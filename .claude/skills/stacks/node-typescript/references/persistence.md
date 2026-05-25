# Persistence (Node.js + TypeScript)

## Goal

Keep data access explicit, typed, testable, and isolated from the domain. ORM types stay inside the
infra layer.

## Repository pattern

The repository exposes domain operations, not generic queries, and returns domain entities — never
ORM models. Map at the boundary.

```typescript
// infra/order/order-mapper.ts
import type { Order as OrderRow } from '@prisma/client'
import { Order } from '../../domain/order/order.js'

export const toDomain = (row: OrderRow): Order =>
  Order.restore({ id: row.id, total: row.totalCents, status: row.status })

export const toPersistence = (order: Order) => ({
  id: order.id,
  totalCents: order.total,
  status: order.status,
})
```

## Prisma

Typed client, parameterized by construction.

```typescript
const order = await prisma.order.findUnique({ where: { id } })
const recent = await prisma.order.findMany({
  where: { customerId, status: 'confirmed' },
  orderBy: { createdAt: 'desc' },
  take: 20,
})
```

### Transactions (own them in the use case)

Manage transactions in the application layer, not in individual repository methods, so one unit of
work spans multiple repositories.

```typescript
// application/order/checkout.ts
await prisma.$transaction(async (tx) => {
  const inventory = new PrismaInventoryRepository(tx)  // pass tx, not the root client
  const orders = new PrismaOrderRepository(tx)
  await inventory.reserve(order.items)
  await orders.save(order)
})
// rollback is automatic if the callback throws
```

Prefer the interactive callback form: it rolls back on any thrown error and keeps the unit of work
explicit. Avoid wrapping a single read in a transaction.

## Drizzle

Typed, SQL-first. Transactions follow the same callback shape.

```typescript
import { drizzle } from 'drizzle-orm/node-postgres'
import { eq } from 'drizzle-orm'
import { orders } from './schema.js'

const db = drizzle(pool)

const [row] = await db.select().from(orders).where(eq(orders.id, id)).limit(1)

await db.transaction(async (tx) => {
  await tx.insert(orders).values(data)
  await tx.update(inventory).set({ qty: sql`${inventory.qty} - ${n}` })
})
```

## Raw pg (parameterized always)

When using the `pg` driver directly, never concatenate input. Use `$1, $2` placeholders.

```typescript
import { Pool } from 'pg'

const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 10 })

const { rows } = await pool.query<OrderRow>(
  'SELECT id, total_cents, status FROM orders WHERE customer_id = $1 AND status = $2',
  [customerId, 'confirmed'],
)
```

```typescript
// transaction with explicit client checkout
const client = await pool.connect()
try {
  await client.query('BEGIN')
  await client.query('UPDATE inventory SET qty = qty - $1 WHERE sku = $2', [n, sku])
  await client.query('INSERT INTO orders (id, total_cents) VALUES ($1, $2)', [id, total])
  await client.query('COMMIT')
} catch (err) {
  await client.query('ROLLBACK')
  throw err
} finally {
  client.release()       // always release back to the pool
}
```

## Connection management

- Configure the pool with explicit limits (`pg` `max`, Prisma `connection_limit` in the URL).
- One pool/client per process; inject it — do not create connections per request.
- Close connections on graceful shutdown: `await prisma.$disconnect()` / `await pool.end()`.
- Apply a statement timeout for long queries when supported.

## Migrations

- Version-controlled, idempotent, and reviewable. Use the adopted tool: `prisma migrate`,
  `drizzle-kit generate` + `migrate`, or a standalone runner (`node-pg-migrate`).
- Separate schema (DDL) migrations from data (DML) migrations when possible.
- Never run destructive migrations automatically in production; gate them behind a deploy step.

```bash
npx prisma migrate dev --name add_order_status      # development
npx prisma migrate deploy                            # CI/production, applies pending only
```

## Common risks

- A repository that returns ORM models instead of domain entities.
- A transaction without error handling, so a partial write is committed.
- Connection leaks from a pool/client that is never closed at shutdown.
- N+1 queries from looping over results and querying inside the loop — batch or join instead.

## Forbidden

- SQL injection via string concatenation of input.
- The domain importing an ORM package or DB driver.
- Long-running transactions without a timeout.
