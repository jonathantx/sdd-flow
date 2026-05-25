# Security (Node.js + TypeScript)

## Goal

Protect the service against the common ways Node backends get compromised. Validate everything from
the outside, never trust the client, keep secrets out of code and logs.

## Input validation and sanitization

- Validate and sanitize every external input: body, query, params, headers, cookies.
- Use typed validation (`zod`, `joi`, `class-validator`) at the transport boundary, then trust the
  parsed result downstream.
- Cap request body size to prevent memory-exhaustion DoS: `express.json({ limit: '1mb' })`.
- Never use client input to make authorization decisions (e.g. trusting a `role` field from the body).

```typescript
const updateUserSchema = z.object({
  email: z.string().email().max(254),
  name: z.string().min(1).max(100).trim(),
}).strict()  // .strict() rejects unknown keys — blocks mass-assignment
```

## Authentication and authorization

- Authenticate in middleware; authorize in the use case or controller where the resource is known.
- Verify the token on every request — never cache an auth decision across requests.
- For JWT, verify signature **and** `exp`, `iss`, and `aud`. A signature-only check is a common, real
  vulnerability.

```typescript
import { jwtVerify } from 'jose'

const { payload } = await jwtVerify(token, key, {
  issuer: 'https://auth.example.com',
  audience: 'orders-api',
})   // throws on expired/invalid signature/wrong aud — do not catch and ignore
```

- Apply least privilege: check the specific permission for the action, not just "is logged in".
- For passwords, hash with `argon2` (preferred) or `bcrypt` — never SHA/MD5, never plaintext.

```typescript
import argon2 from 'argon2'
const hash = await argon2.hash(password)            // on signup
const ok = await argon2.verify(hash, attempt)        // on login
```

## Secrets

- Load secrets from environment variables or a secret manager — never hardcoded, never committed.
- Validate env at startup so the process fails fast on a missing secret.
- Never log secrets, tokens, or credentials at any level. Never put them in error responses.

```typescript
const env = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
}).parse(process.env)   // crashes at boot if misconfigured — better than a runtime surprise
```

## HTTP hardening

- Use `helmet` for security headers (`Content-Security-Policy`, `X-Content-Type-Options`, HSTS).
- Configure CORS with an explicit allow-list of origins — never `*` in production with credentials.
- Rate-limit public and auth endpoints (`express-rate-limit`), especially `/login`.

```typescript
import helmet from 'helmet'
import rateLimit from 'express-rate-limit'

app.use(helmet())
app.use('/auth/login', rateLimit({ windowMs: 60_000, max: 5 }))
app.use(cors({ origin: ['https://app.example.com'], credentials: true }))
```

## Common OWASP risks in Node

- **Injection** — SQL/NoSQL/command injection. Parameterize queries; never build SQL by concatenation;
  never pass user input to `child_process.exec` (use `execFile` with an args array).
- **Prototype pollution** — merging untrusted objects can poison `Object.prototype`. Use `.strict()`
  schemas, avoid deep-merge of raw input, and guard against `__proto__`/`constructor` keys.
- **SSRF** — validate and allow-list outbound URLs built from user input before fetching them.
- **ReDoS** — avoid catastrophic-backtracking regexes on user input; cap input length first.
- **Insecure deserialization** — never `eval()` or `new Function()` on input; never `JSON.parse` a
  reviver that executes input.
- **Path traversal** — when serving files from user input, resolve and confirm the path stays inside
  the intended directory.

```typescript
import { resolve } from 'node:path'
const base = resolve('/srv/uploads')
const target = resolve(base, userPath)
if (!target.startsWith(base + '/')) throw new ForbiddenError('path traversal')
```

## Dependencies / supply chain

- Run `npm audit` / `pnpm audit` in CI and fail on high-severity findings.
- Keep dependencies updated in a controlled way (Renovate/Dependabot).
- Consider `snyk` or `socket.dev` for supply-chain analysis. Pin versions with a committed lockfile.

## Forbidden

- A secret hardcoded in code or committed to the repo.
- SQL built by string concatenation with external input.
- Error responses exposing stack traces or internal paths.
- `eval()` or `new Function()` on user input.
- JWT accepted on signature alone without checking expiry and audience.
