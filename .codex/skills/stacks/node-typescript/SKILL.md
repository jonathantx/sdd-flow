---
name: node-typescript
version: 1.0.0
description: Activate when implementing, fixing, refactoring, or reviewing backend code on a Node.js + TypeScript stack — HTTP APIs (Express/Fastify), data access (Prisma/Drizzle/pg), tests (Vitest/Jest), logging, security, or project structure. Do not use for frontend-only or non-Node tasks.
---

# Node.js + TypeScript Implementation

## When this is used

Use this skill any time the task touches a Node.js backend written in TypeScript: building an
endpoint, wiring a repository, adding tests, hardening security, or organizing the codebase. It is
the knowledge base that keeps implementation correct, typed, and consistent with industry practice.

## References

Load only what the task needs.

- `references/architecture.md` — project layout, domain/use-case/adapter layers, dependency injection, folder structure.
- `references/api.md` — HTTP API design with Express/Fastify, zod validation, error handling, status codes, DTOs and contracts.
- `references/persistence.md` — data access with Prisma/Drizzle/pg, transactions, migrations, the repository pattern.
- `references/testing.md` — unit and integration tests with Vitest/Jest, mocks, test doubles, coverage, the AAA pattern.
- `references/security.md` — input validation, sanitization, secrets, auth, and common OWASP risks in Node.
- `references/observability.md` — structured logging with pino, metrics, tracing, request correlation.
- `references/conventions.md` — TS style, naming, strict tsconfig, lint/format, imports, null/undefined handling.

## Golden rules

- Keep handlers thin: extract input, call a use case, format the response. No business logic in transport.
- Always validate external input at the boundary (zod) before it reaches the domain.
- Depend on interfaces at IO boundaries; inject concrete adapters via constructors/factories.
- Repositories expose domain operations and return domain entities — never leak ORM types.
- `strict: true` always. Avoid `any`; prefer `unknown` and narrow. No type assertions to silence the compiler.
- Manage transactions in the use case, never in a single repository method.
- Test behavior, not implementation; mock only external boundaries; keep tests deterministic.
- Never log secrets or PII. Never expose stack traces in responses. Always parameterize queries.
- Read `package.json` (engines, scripts, deps) before assuming runtime, tooling, or libraries.
