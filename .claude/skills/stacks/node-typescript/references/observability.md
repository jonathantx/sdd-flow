# Observability (Node.js + TypeScript)

## Goal

Make the running service traceable and diagnosable in production: structured logs, request
correlation, traces on meaningful operations, and a few high-signal metrics.

## Structured logging with pino

Log JSON with consistent fields (`level`, `msg`, `err`, `traceId`, `requestId`). Prefer `pino` as the
default; use `winston` only if the project already uses it. `pino` is fast and async, so it won't stall
the event loop on a hot path.

```typescript
// config/logger.ts
import pino from 'pino'

export const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  redact: ['req.headers.authorization', 'password', '*.token'], // never log secrets/PII
  formatters: { level: (label) => ({ level: label }) },
})
```

Log levels with intent:

- `debug` — local development detail, off in production.
- `info` — operational events (server started, order confirmed).
- `warn` — tolerated degradation (retry succeeded, cache miss spike).
- `error` — a failure needing attention. Always pass the error object: `logger.error({ err }, 'msg')`.

Log at IO boundaries, on errors, and on meaningful business decisions — not on every line.

## Request correlation

Attach a request ID to every incoming request and propagate it into the logger and downstream calls.
Use `AsyncLocalStorage` so the ID is available without threading it through every function.

```typescript
// http/middlewares/request-context.ts
import { AsyncLocalStorage } from 'node:async_hooks'
import { randomUUID } from 'node:crypto'
import type { RequestHandler } from 'express'
import { logger } from '../../config/logger.js'

export const requestContext = new AsyncLocalStorage<{ requestId: string }>()

export const withRequestContext: RequestHandler = (req, res, next) => {
  const requestId = (req.headers['x-request-id'] as string) ?? randomUUID()
  res.setHeader('x-request-id', requestId)
  requestContext.run({ requestId }, () => {
    req.log = logger.child({ requestId })   // every log line in this request carries the id
    next()
  })
}
```

`pino-http` wires per-request logging automatically and is the simplest path for Express/Fastify:

```typescript
import pinoHttp from 'pino-http'
app.use(pinoHttp({ logger, genReqId: (req) => req.headers['x-request-id'] ?? randomUUID() }))
```

## Distributed tracing with OpenTelemetry

Use the OpenTelemetry SDK (`@opentelemetry/sdk-node`) with auto-instrumentation. It propagates trace
context across HTTP clients and ORMs for free. Initialize it before any other import.

```typescript
// tracing.ts — imported first via `node --import ./tracing.js`
import { NodeSDK } from '@opentelemetry/sdk-node'
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node'

const sdk = new NodeSDK({ instrumentations: [getNodeAutoInstrumentations()] })
sdk.start()
```

Add manual spans only around operations with meaningful latency (external calls, expensive compute).
Name spans by role, not by internal function name.

```typescript
import { trace } from '@opentelemetry/api'
const tracer = trace.getTracer('orders')

await tracer.startActiveSpan('reserve-inventory', async (span) => {
  try {
    await inventory.reserve(items)
  } finally {
    span.end()
  }
})
```

## Metrics

Expose a small, high-signal set: request count, latency histogram, error rate, resource saturation.
Use labels with **controlled cardinality** — never a user ID, request ID, or other unbounded value as a
label, or the time-series count explodes. Prefer histograms over summaries for latency.

```typescript
import { Counter, Histogram } from 'prom-client'

const httpRequests = new Counter({
  name: 'http_requests_total',
  help: 'total HTTP requests',
  labelNames: ['method', 'route', 'status'],  // bounded labels only
})
const httpDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'request latency',
  labelNames: ['method', 'route'],
})
```

## Health checks

Expose separate liveness and readiness endpoints.

- **Liveness** (`/healthz`) — is the process alive? Must NOT check external dependencies, or a slow DB
  triggers needless restarts.
- **Readiness** (`/readyz`) — are critical dependencies (DB, cache, queue) reachable? Use a short
  timeout so a hung dependency fails fast instead of cascading.

```typescript
app.get('/healthz', (_req, res) => res.status(200).send('ok'))
app.get('/readyz', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`
    res.status(200).send('ready')
  } catch {
    res.status(503).send('not ready')
  }
})
```

## Common risks

- Excessive logging on a hot path degrading event-loop throughput.
- High-cardinality metric labels exploding the number of time series.
- A readiness check without a timeout, turning one slow dependency into a cascading outage.

## Forbidden

- `console.log` in production code as a substitute for a structured logger.
- Logging tokens, secrets, or PII (configure `redact`).
- Dropping trace context on service-to-service calls.
