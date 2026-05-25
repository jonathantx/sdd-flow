# Architecture (Node.js + TypeScript)

## Goal

Keep business rules independent of frameworks, IO, and delivery mechanisms. Dependencies point
inward: transport depends on use cases, use cases depend on the domain, and the domain depends on
nothing external.

## Layers

| Layer | Responsibility | Depends on |
| --- | --- | --- |
| `domain` | Entities, value objects, invariants, port interfaces | nothing |
| `application` | Use cases orchestrating domain + ports | `domain` |
| `infra` | Concrete adapters: repositories, clients, queues | `domain` (implements ports) |
| `http` / `workers` | Controllers, DTOs, middlewares, consumers | `application` |

The domain never imports a framework, ORM, or driver. If `domain/` imports `prisma` or `express`,
the dependency rule is broken.

## Recommended folder structure

### HTTP / gRPC API

```
src/
  domain/order/
    order.ts                # entity + invariants
    order-repository.ts      # port (interface)
  application/order/
    confirm-order.ts         # use case
  infra/order/
    prisma-order-repository.ts
  http/
    controllers/order-controller.ts
    dtos/confirm-order.dto.ts
    middlewares/
  config/                    # env loading, composition root
  server.ts                  # wires everything, starts listener
test/                        # or *.test.ts colocated next to source
```

### Worker / consumer

```
src/
  domain/  application/  infra/
  workers/order-confirmed.consumer.ts
```

Rules: `src/` holds code; tests are colocated or under `__tests__/`. Avoid catch-all `utils/` or
`helpers/` that mix unrelated concerns. Maximum useful depth is `src/<layer>/<module>/`.

## Ports and adapters

Define the contract the domain needs as an interface, implement it in `infra`.

```typescript
// domain/order/order-repository.ts
import type { Order } from './order.js'

export interface OrderRepository {
  findById(id: string): Promise<Order | null>
  save(order: Order): Promise<void>
}
```

```typescript
// infra/order/prisma-order-repository.ts
import type { PrismaClient } from '@prisma/client'
import type { Order } from '../../domain/order/order.js'
import type { OrderRepository } from '../../domain/order/order-repository.js'
import { toDomain, toPersistence } from './order-mapper.js'

export class PrismaOrderRepository implements OrderRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<Order | null> {
    const row = await this.prisma.order.findUnique({ where: { id } })
    return row ? toDomain(row) : null
  }

  async save(order: Order): Promise<void> {
    const data = toPersistence(order)
    await this.prisma.order.upsert({ where: { id: data.id }, create: data, update: data })
  }
}
```

## Dependency injection

Prefer constructor injection and factory functions over magic containers. Reach for `tsyringe`,
`inversify`, or NestJS modules only when the project already uses one.

```typescript
// application/order/confirm-order.ts
import type { OrderRepository } from '../../domain/order/order-repository.js'

export class ConfirmOrder {
  constructor(private readonly orders: OrderRepository) {}

  async execute(orderId: string): Promise<void> {
    const order = await this.orders.findById(orderId)
    if (!order) throw new NotFoundError(`order ${orderId} not found`)
    order.confirm()                 // invariant lives in the entity
    await this.orders.save(order)
  }
}
```

### Composition root

Build the graph once, at startup. Nothing else calls `new` on an adapter.

```typescript
// config/container.ts
import { PrismaClient } from '@prisma/client'
import { PrismaOrderRepository } from '../infra/order/prisma-order-repository.js'
import { ConfirmOrder } from '../application/order/confirm-order.js'

export function buildContainer() {
  const prisma = new PrismaClient()
  const orderRepo = new PrismaOrderRepository(prisma)
  return {
    prisma,
    confirmOrder: new ConfirmOrder(orderRepo),
  }
}
```

## Factory functions vs classes

Prefer factory functions when there is no mutable state; prefer a class when construction validates
input or carries identity/lifecycle. Both are fine for use cases — pick what the team uses.

```typescript
export function createConfirmOrder(orders: OrderRepository) {
  return async (orderId: string): Promise<void> => {
    const order = await orders.findById(orderId)
    if (!order) throw new NotFoundError(`order ${orderId} not found`)
    order.confirm()
    await orders.save(order)
  }
}
```

## Signs of over-engineering

- An interface with a single implementation that will never have a second one.
- A use case that only forwards to a repository (skip the layer — call it from the controller).
- Generic `BaseService<T>` / `BaseRepository<T>` hierarchies that obscure intent.
- Mappers between identical shapes. Map only when domain and persistence shapes truly differ.

Add a layer when it removes a real dependency or isolates a real risk — not preemptively.
