# Conventions (PHP + Laravel)

## Goal
Code that looks like the rest of the Laravel ecosystem so any contributor reads it instantly.

## strict_types and typing
Every PHP file starts with:
```php
<?php

declare(strict_types=1);
```
Type everything — parameters, return types, properties. Use union and nullable types where real, and
`void`/`never` where appropriate. Avoid `mixed` unless genuinely unavoidable.
```php
public function find(int $id): ?Order { /* ... */ }
public function total(): int { /* ... */ }
```

## PHP 8.2+ features to prefer
- **Constructor promotion:** declare and assign in the signature.
  ```php
  public function __construct(private readonly OrderRepository $orders) {}
  ```
- **`readonly` properties/classes** for immutable DTOs and value objects.
- **Backed enums** instead of class constants for fixed sets (see `architecture.md`).
- **`match`** instead of long `switch`/`if-else` chains (strict comparison, exhaustive, returns a value).
- **Named arguments** for clarity when calling with many/optional params.
- **First-class callable syntax:** `array_map(Item::fromArray(...), $rows)`.
- **Nullsafe operator:** `$order?->customer?->name`.

## PSR-12 + Laravel style
Follow PSR-12 (4-space indent, braces, spacing). Laravel layers extra naming conventions on top:
- **Classes:** `StudlyCase` — `OrderController`, `CreateOrderRequest`, `OrderResource`.
- **Methods / variables:** `camelCase` — `createOrder()`, `$totalAmount`.
- **Controllers:** singular resource + `Controller` suffix — `OrderController`.
- **Models:** singular `StudlyCase` — `Order`, `OrderItem`. Tables are plural snake_case — `orders`.
- **Columns:** `snake_case` — `customer_id`, `paid_at`.
- **Migrations:** `create_orders_table`, `add_status_to_orders_table` (timestamped by artisan).
- **Routes:** plural, kebab-case URIs — `/order-items`; named routes dot-notation — `orders.store`.
- **Config keys:** snake_case; **env vars:** UPPER_SNAKE_CASE.
- **Booleans:** prefix `is`/`has`/`can` — `isPaid()`, `hasItems()`.
- **Tests:** `it('...')` / `test('...')` (Pest) or `test_...` methods (PHPUnit).

## Pint (formatter)
Pint is Laravel's official formatter (PHP-CS-Fixer wrapper) using the `laravel` preset. Run it before
finishing; treat its output as canonical — do not hand-format.
```bash
./vendor/bin/pint            # fix
./vendor/bin/pint --test     # CI: fail if not formatted
```
Configure deviations in `pint.json` only when the team agreed.

## Namespaces and organization
- PSR-4 autoloading: namespace mirrors the path under `app/` → `App\` (see `composer.json`).
  `app/Actions/Orders/CreateOrder.php` → `App\Actions\Orders\CreateOrder`.
- One class per file; filename matches the class name exactly.
- Group related classes by domain folder once a directory grows; keep nesting shallow.
- Import with `use` at the top; avoid fully-qualified names inline except for one-off references.
- Mark classes `final` by default — open for extension only when inheritance is intended.

## Other idioms
- Prefer `Order::query()->where(...)` over `Order::where(...)` for readability and easier chaining.
- Use helpers (`now()`, `collect()`, `str()`, `data_get()`) where they read clearly; do not over-use.
- Keep methods small and single-purpose; extract an Action when logic grows.
- Comments explain WHY, not WHAT; delete commented-out code.
- PHPDoc only where types cannot express the shape (e.g. `array<int, Order>`, generics).

## Common risks
- Missing `declare(strict_types=1)` causing silent type coercion.
- Inconsistent naming (plural model, snake_case method) confusing readers.
- Hand-formatting that conflicts with Pint and churns diffs.
- Deeply nested namespaces or god-folders like `Helpers/` mixing concerns.

## Quick reference: artisan generators
Let artisan scaffold files so naming and location are always correct:
```bash
php artisan make:controller OrderController --api
php artisan make:request CreateOrderRequest
php artisan make:resource OrderResource
php artisan make:model Order -mfs   # migration + factory + seeder
php artisan make:policy OrderPolicy --model=Order
php artisan make:enum OrderStatus   # via packages; or hand-write under app/Enums
```

## Forbidden
- Untyped public APIs (no param/return types) on new code.
- Bypassing Pint with manual formatting in the same PR.
- `env()` calls outside `config/` (breaks `config:cache`).
