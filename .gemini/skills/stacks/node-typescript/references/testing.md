# Testing (Node.js + TypeScript)

## Goal

Prove correctness, prevent regressions, and document behavior at a cost proportional to risk. Test
behavior, not implementation.

## Principles

- Use the framework the project already adopted (Vitest, Jest, or `node:test`).
- Name tests by scenario, not by method: `confirms a pending order`, `rejects an already-shipped order`.
- Keep tests deterministic: no real timers, no ordering dependence, no shared mutable state.
- Mock only external boundaries (network, DB, filesystem, clock). Never mock the unit under test.
- Reset mocks in `beforeEach`; never share a mutable instance across cases.
- Follow AAA: **Arrange** the inputs and doubles, **Act** by calling the unit, **Assert** the outcome.

## Unit test with the AAA pattern (Vitest)

```typescript
// application/order/confirm-order.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ConfirmOrder } from './confirm-order.js'
import { Order } from '../../domain/order/order.js'
import { NotFoundError } from '../../domain/errors.js'
import type { OrderRepository } from '../../domain/order/order-repository.js'

const makeRepo = (): OrderRepository => ({
  findById: vi.fn(),
  save: vi.fn().mockResolvedValue(undefined),
})

describe('ConfirmOrder', () => {
  let repo: OrderRepository
  let useCase: ConfirmOrder

  beforeEach(() => {
    repo = makeRepo()
    useCase = new ConfirmOrder(repo)
  })

  it('confirms a pending order', async () => {
    // Arrange
    const order = Order.create('order-1', 5000)
    vi.mocked(repo.findById).mockResolvedValue(order)

    // Act
    await useCase.execute('order-1')

    // Assert
    expect(order.status).toBe('confirmed')
    expect(repo.save).toHaveBeenCalledOnce()
  })

  it('throws when the order does not exist', async () => {
    vi.mocked(repo.findById).mockResolvedValue(null)
    await expect(useCase.execute('missing')).rejects.toThrow(NotFoundError)
    expect(repo.save).not.toHaveBeenCalled()
  })
})
```

## Test doubles

- **Stub** — returns canned data (`findById` returning a fixed order).
- **Mock** — verifies an interaction happened (`expect(repo.save).toHaveBeenCalledWith(...)`).
- **Fake** — a working lightweight implementation (an in-memory repository) — great for use-case tests
  without a real DB.

```typescript
// in-memory fake repository for fast, realistic tests
class InMemoryOrderRepository implements OrderRepository {
  private store = new Map<string, Order>()
  async findById(id: string) { return this.store.get(id) ?? null }
  async save(o: Order) { this.store.set(o.id, o) }
}
```

## Parametrized tests

```typescript
it.each([
  ['pending', true],
  ['shipped', false],
  ['cancelled', false],
])('canConfirm(%s) === %s', (status, expected) => {
  expect(Order.restore({ id: 'x', total: 1, status }).canConfirm()).toBe(expected)
})
```

## Controlling time and randomness

Never sleep in a test. Use fake timers and inject the clock.

```typescript
beforeEach(() => vi.useFakeTimers({ now: new Date('2026-01-01') }))
afterEach(() => vi.useRealTimers())
// vi.advanceTimersByTime(1000) to move time forward deterministically
```

## Integration tests

Separate them from unit tests with a dedicated script (`npm run test:integration`) so they never run
in the fast feedback loop. Provision real dependencies in ephemeral containers with
[testcontainers](https://node.testcontainers.org/); never point at a shared dev DB or staging API.

```typescript
// infra/order/order-repository.integration.test.ts
import { describe, it, beforeAll, afterAll, expect } from 'vitest'
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'

describe('PrismaOrderRepository (integration)', () => {
  let container: StartedPostgreSqlContainer

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:16-alpine').start()
    // run migrations against container.getConnectionUri()
  }, 60_000)

  afterAll(async () => {
    await container.stop()
  })

  it('saves and reloads an order by id', async () => {
    // instantiate the repository against the container URI and assert real behavior
  })
})
```

## HTTP endpoint tests

Use `supertest` (Express) or `app.inject()` (Fastify) to exercise the route without a network socket.

```typescript
import request from 'supertest'
import { buildApp } from '../server.js'

it('returns 400 on invalid body', async () => {
  const res = await request(buildApp()).post('/orders').send({ items: [] })
  expect(res.status).toBe(400)
})
```

## Coverage

Track coverage as a signal, not a target. Prioritize use cases, domain invariants, and error paths.
Don't chase 100% by testing trivial getters. Configure thresholds in `vitest.config.ts`:

```typescript
test: { coverage: { provider: 'v8', thresholds: { lines: 80, functions: 80 } } }
```

## Forbidden

- `setTimeout` to synchronize a test.
- A test that passes alone but fails in the full suite (hidden shared state).
- A mock that does not match the real dependency's contract.
- Integration tests running together with unit tests in the default script.
