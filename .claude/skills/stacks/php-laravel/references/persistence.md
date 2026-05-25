# Persistence (PHP + Laravel)

## Goal
Use Eloquent idiomatically, keep migrations safe, and never ship an N+1 query.

## Models
Type properties via casts; declare relationships with return types; restrict mass assignment.
```php
final class Order extends Model
{
    protected $fillable = ['customer_id', 'total', 'status'];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'status'    => OrderStatus::class,
            'total'     => 'integer',
            'paid_at'   => 'datetime',
        ];
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
```
Laravel 11 prefers the `casts()` method over the `$casts` property.

## Migrations
Versioned, reversible DDL. One concern per migration. Add indexes for foreign keys and lookups.
```php
return new class extends Migration {
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('total');
            $table->string('status')->default('pending')->index();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```
Keep data backfills in separate migrations from schema changes. Never edit a migration that already
ran in shared environments — write a new one.

## Relationships
Use the relationship that matches the schema: `hasMany`, `belongsTo`, `belongsToMany` (pivot),
`hasManyThrough`, `morphMany` (polymorphic). Name methods after the relationship subject.

## Query optimization — fix N+1
The classic bug: looping models and touching a relationship lazily.
```php
// BAD: 1 query for orders + 1 per order for customer (N+1)
foreach (Order::all() as $order) {
    echo $order->customer->name;
}

// GOOD: eager load up front (2 queries total)
$orders = Order::with('customer')->get();

// Nested + constrained
$orders = Order::with(['items' => fn ($q) => $q->where('qty', '>', 0)])->get();

// Aggregates without loading rows
$orders = Order::withCount('items')->get();   // $order->items_count
```
Enable `Model::preventLazyLoading()` in non-production to make N+1 throw during development.
Select only needed columns on hot paths: `Order::select(['id', 'total'])->get();`

## Transactions
Wrap any operation that writes to more than one row/table and must be atomic.
```php
DB::transaction(function () use ($data): void {
    $order = Order::create($data->toArray());
    $order->items()->createMany($data->items);
    Inventory::decrement(...);
}); // auto-rollback on exception
```
Do not open a transaction for a single read. Avoid HTTP/queue calls inside a transaction — they hold
locks; dispatch jobs after commit (`DB::afterCommit()` or `$job->afterCommit()`).

## Factories and seeders
Factories generate test/dev data; define realistic states.
```php
final class OrderFactory extends Factory
{
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            'total'       => fake()->numberBetween(100, 10_000),
            'status'      => OrderStatus::Pending,
        ];
    }

    public function paid(): self
    {
        return $this->state(['status' => OrderStatus::Paid, 'paid_at' => now()]);
    }
}
```
Use in tests: `Order::factory()->count(3)->paid()->create();`. Seeders compose factories for local data.

## Common risks
- N+1 from lazy relationship access in loops or Resources.
- Mass assignment with no `$fillable`/`$guarded`.
- Long-running external calls inside a DB transaction (lock contention).
- Editing already-applied migrations instead of adding new ones.

## Forbidden
- Raw string-concatenated SQL with user input (use bindings / the query builder).
- `Model::create($request->all())` without controlled `$fillable`.
- Destructive migrations run automatically against production without review.
