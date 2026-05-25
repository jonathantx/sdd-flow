# Architecture (PHP + Laravel)

## Goal
Keep business logic out of controllers and models so code stays testable and changes stay local.

## Standard directory layout
Laravel ships an `app/` MVC skeleton. Organize *inside* it instead of inventing parallel trees:
```
app/
  Actions/<Domain>/          # single-purpose use cases (CreateOrder, CancelSubscription)
  Data/                      # DTOs (request/response shapes), often readonly classes
  Enums/                     # backed enums for states/types
  Http/
    Controllers/             # thin HTTP entrypoints
    Requests/                # FormRequest validation
    Resources/               # API Resources (response shaping)
  Models/                    # Eloquent models
  Policies/                  # authorization
  Services/                  # multi-step orchestration when Action is too small a unit
  Repositories/              # ONLY when justified (see below)
```
Group by feature/domain once a folder grows past ~8 files (`app/Actions/Billing/...`).

## Action classes (preferred unit of business logic)
One public method, one responsibility. Inject dependencies via constructor promotion.
```php
<?php

declare(strict_types=1);

namespace App\Actions\Orders;

use App\Data\CreateOrderData;
use App\Models\Order;
use Illuminate\Support\Facades\DB;

final readonly class CreateOrder
{
    public function __construct(private InventoryService $inventory) {}

    public function handle(CreateOrderData $data): Order
    {
        return DB::transaction(function () use ($data): Order {
            $this->inventory->reserve($data->items);

            return Order::create([
                'customer_id' => $data->customerId,
                'total'       => $data->total,
                'status'      => OrderStatus::Pending,
            ]);
        });
    }
}
```
A controller then does: `$order = $action->handle($data);`. Actions are trivially unit-testable.

## Service classes
Use a `Service` when behavior is reused by several Actions/Controllers or wraps an external system
(`PaymentGateway`, `InventoryService`). If a class would have exactly one method and one caller,
prefer an Action instead — do not create a service for ceremony.

## DTOs (Data Transfer Objects)
Carry validated, typed data between layers. Avoid passing raw `Request` or arrays deep into the app.
```php
final readonly class CreateOrderData
{
    /** @param array<int, OrderItem> $items */
    public function __construct(
        public int $customerId,
        public int $total,
        public array $items,
    ) {}

    public static function fromRequest(CreateOrderRequest $request): self
    {
        $v = $request->validated();

        return new self(
            customerId: $v['customer_id'],
            total: $v['total'],
            items: array_map(OrderItem::fromArray(...), $v['items']),
        );
    }
}
```
The `spatie/laravel-data` package is a fine standard choice; plain readonly classes work too.

## Enums for states and types
Backed enums replace magic strings and `const` soup:
```php
enum OrderStatus: string
{
    case Pending  = 'pending';
    case Paid     = 'paid';
    case Cancelled = 'cancelled';

    public function isFinal(): bool
    {
        return match ($this) {
            self::Paid, self::Cancelled => true,
            self::Pending               => false,
        };
    }
}
```
Cast on the model: `protected $casts = ['status' => OrderStatus::class];`

## When to use a Repository
Eloquent IS already a data-access layer. Add a Repository only when:
- You need to swap the data source (DB vs external API) behind one interface.
- Query logic is complex and reused across many call sites.
- A domain boundary must not import Eloquent at all.

Otherwise, query directly with Eloquent (or Query Scopes on the model). A repository that just wraps
`Model::find()` adds indirection with no payoff — do not add it by default.

```php
interface OrderRepository
{
    public function findActiveForCustomer(int $customerId): Collection;
}

final class EloquentOrderRepository implements OrderRepository
{
    public function findActiveForCustomer(int $customerId): Collection
    {
        return Order::query()
            ->where('customer_id', $customerId)
            ->whereIn('status', [OrderStatus::Pending, OrderStatus::Paid])
            ->get();
    }
}
```
Bind it in a service provider: `$this->app->bind(OrderRepository::class, EloquentOrderRepository::class);`

## Common risks
- Fat controllers holding business rules instead of delegating to Actions.
- "God" `Service` classes that accumulate unrelated methods.
- Repositories added reflexively, duplicating Eloquent for no benefit.
- Passing `$request->all()` arrays through layers instead of typed DTOs.

## Forbidden
- Business logic inside Blade views or route closures.
- Models containing HTTP/transport concerns.
- Layers below `Http/` depending on `Illuminate\Http\Request`.
