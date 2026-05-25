# Conventions (Node.js + TypeScript)

## Goal

Preserve consistency, boundaries, and readability. Above all, match the style already used in the
project (ESM vs CJS, quotes, semicolons, indentation) rather than imposing a new one.

## Strict tsconfig

Start every new project with strict mode and a few extra guards. These catch real bugs at compile
time.

```jsonc
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,                          // implies noImplicitAny, strictNullChecks, etc.
    "noUncheckedIndexedAccess": true,        // arr[i] is T | undefined — forces a check
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true,            // explicit `import type`
    "skipLibCheck": true,
    "outDir": "dist",
    "rootDir": "src"
  }
}
```

## TypeScript style

- Prefer `const`; use `let` only when reassigning; never `var`.
- Avoid `any`. Use `unknown` for genuinely unknown input and narrow it before use.
- Prefer generics over type assertions. An `as` cast silences the compiler instead of proving the type.
- Use `interface` for public/extensible contracts, `type` for unions, intersections, and mapped types.
- Prefer pure functions and composition over class inheritance.
- Mark immutable data `readonly`; use `as const` for literal tuples and config objects.

```typescript
// narrow unknown instead of casting
function parsePort(value: unknown): number {
  if (typeof value !== 'string') throw new TypeError('PORT must be a string')
  const n = Number(value)
  if (!Number.isInteger(n)) throw new TypeError('PORT must be an integer')
  return n
}
```

## Null and undefined

- Enable `strictNullChecks` (via `strict`). Model "absent" with `undefined`; reserve `null` for an
  intentional, stored empty value (and stay consistent).
- Use optional chaining and nullish coalescing, but only `??` (not `||`) when `0`/`''`/`false` are
  valid values.

```typescript
const limit = query.limit ?? 20          // keeps 0 if explicitly provided; || would replace it
const city = user.address?.city
```

- Avoid the non-null assertion `!`. If you know it's defined, narrow with a guard so the compiler
  agrees:

```typescript
const order = await repo.findById(id)
if (!order) throw new NotFoundError(id)
order.confirm()   // typed as Order here, no `!` needed
```

## Naming

- `camelCase` for variables and functions, `PascalCase` for types/classes, `UPPER_SNAKE` for module-
  level constants.
- Files in `kebab-case` (`confirm-order.ts`) or whatever the project already uses — be consistent.
- Booleans read as predicates: `isActive`, `hasItems`, `canConfirm`.
- Name by intent, not type: `orders`, not `orderArray`.

## Imports

- Order: Node built-ins, then external dependencies, then internal modules. Keep groups separated.
- Use the `node:` protocol for built-ins: `import { readFile } from 'node:fs/promises'`.
- Use `import type` for type-only imports (required with `verbatimModuleSyntax`).
- In ESM projects, include the file extension in relative imports (`./order.js`) and avoid `require()`.

```typescript
import { randomUUID } from 'node:crypto'

import { z } from 'zod'

import type { OrderRepository } from '../domain/order/order-repository.js'
import { ConfirmOrder } from './confirm-order.js'
```

## Async

- Always `await` or explicitly `void` a promise — never leave a floating promise (enable
  `no-floating-promises`).
- Run independent async work concurrently with `Promise.all`; use `Promise.allSettled` when partial
  failure is acceptable.
- Catch errors at the boundary that can act on them, not at every call site.

## Lint and format

- ESLint flat config with `typescript-eslint` (recommended-type-checked) + Prettier for formatting.
  Let Prettier own style; let ESLint own correctness.
- Useful rules: `@typescript-eslint/no-floating-promises`, `no-explicit-any`, `consistent-type-imports`.
- Wire `npm run lint`, `npm run format`, `npm run typecheck` and run them in CI.

```jsonc
// package.json scripts
{
  "typecheck": "tsc --noEmit",
  "lint": "eslint . --max-warnings 0",
  "format": "prettier --write .",
  "test": "vitest run"
}
```

## Forbidden

- Assuming a Node version without checking `engines` in `package.json` or `.nvmrc`.
- Installing a dependency without checking whether the project already has an equivalent.
- `require()` in an ESM project without justification.
- `// @ts-ignore` to silence an error instead of fixing the type (use `@ts-expect-error` with a reason
  only when truly unavoidable).
