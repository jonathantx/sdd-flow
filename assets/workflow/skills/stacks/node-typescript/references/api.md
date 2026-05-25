# HTTP API Design (Express / Fastify)

## Goal

Thin handlers, explicit contracts, and a clean split between transport and business logic.

## Handlers / controllers

A handler does three things: parse and validate input, call a use case, format the response. No
domain rules, no orchestration, no data access inside the handler.

```typescript
// http/controllers/order-controller.ts (Express)
import type { Request, Response, NextFunction } from 'express'
import { confirmOrderSchema } from '../dtos/confirm-order.dto.js'
import type { ConfirmOrder } from '../../application/order/confirm-order.js'

export class OrderController {
  constructor(private readonly confirmOrder: ConfirmOrder) {}

  confirm = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { id } = confirmOrderSchema.parse({ id: req.params.id })
      await this.confirmOrder.execute(id)
      res.status(204).send()
    } catch (err) {
      next(err) // delegate to the global error middleware
    }
  }
}
```

## Input validation with zod

Validate the structure at the transport boundary. Parse, then trust the typed result. Never read
raw `req.body` after validation.

```typescript
// http/dtos/confirm-order.dto.ts
import { z } from 'zod'

export const confirmOrderSchema = z.object({
  id: z.string().uuid(),
})

export const createOrderSchema = z.object({
  customerId: z.string().uuid(),
  items: z.array(z.object({
    sku: z.string().min(1),
    quantity: z.number().int().positive(),
  })).min(1),
  note: z.string().max(500).optional(),
})

export type CreateOrderDto = z.infer<typeof createOrderSchema>
```

A reusable validation middleware keeps controllers clean:

```typescript
import type { ZodSchema } from 'zod'
import type { RequestHandler } from 'express'

export const validateBody = (schema: ZodSchema): RequestHandler => (req, _res, next) => {
  const result = schema.safeParse(req.body)
  if (!result.success) return next(new ValidationError(result.error.issues))
  req.body = result.data
  next()
}
```

## Status codes

| Code | When |
| --- | --- |
| 200 | Successful read or update returning a body |
| 201 | Resource created (return `Location` or the body) |
| 204 | Success with no body |
| 400 | Malformed/invalid input (schema failure) |
| 401 | Missing or invalid authentication |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict (duplicate, optimistic-lock failure) |
| 422 | Valid shape but a domain rule rejected it |
| 429 | Rate limited |
| 500 | Unexpected server error |

## Error handling

Map domain/error types to status codes in one global error middleware. Never expose stack traces.

```typescript
// http/middlewares/error-handler.ts
import type { ErrorRequestHandler } from 'express'
import { ZodError } from 'zod'
import { NotFoundError, ConflictError, DomainRuleError } from '../../domain/errors.js'

export const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
  if (err instanceof ZodError) {
    return res.status(400).json({ error: 'validation_failed', details: err.issues })
  }
  if (err instanceof NotFoundError) return res.status(404).json({ error: err.message })
  if (err instanceof ConflictError) return res.status(409).json({ error: err.message })
  if (err instanceof DomainRuleError) return res.status(422).json({ error: err.message })

  req.log.error({ err }, 'unhandled error')   // log full detail server-side
  return res.status(500).json({ error: 'internal_error' }) // generic to the client
}
```

Define typed domain errors so the mapping is exhaustive:

```typescript
// domain/errors.ts
export class NotFoundError extends Error {}
export class ConflictError extends Error {}
export class DomainRuleError extends Error {}
```

## Fastify equivalent

Fastify offers first-class schema validation and a typed request via `@fastify/type-provider-zod`.

```typescript
import Fastify from 'fastify'
import { serializerCompiler, validatorCompiler } from 'fastify-type-provider-zod'

const app = Fastify({ logger: true })
app.setValidatorCompiler(validatorCompiler)
app.setSerializerCompiler(serializerCompiler)

app.post('/orders', { schema: { body: createOrderSchema } }, async (req, reply) => {
  const order = await createOrder.execute(req.body) // req.body is typed
  return reply.code(201).send(order)
})
```

## Contracts and versioning

- Keep request/response DTOs separate from domain entities. Never serialize a domain entity directly.
- Version by path (`/v1/`, `/v2/`) only when a breaking change is unavoidable; each version owns its
  DTO adapters but reuses the same use case.

## Pagination

Prefer cursor-based pagination for large datasets; offset for small, stable ones. Always set a
default and maximum `limit`, and return `nextCursor` and `hasMore`.

```typescript
const querySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  cursor: z.string().optional(),
})
```

## Forbidden

- Business rules in a handler or middleware.
- Stack traces or internal paths leaking into responses.
- Handlers that grow to hundreds of lines mixing concerns.
- Ignoring request cancellation (`AbortSignal`) on long operations.
