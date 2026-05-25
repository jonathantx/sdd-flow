# Testing (PHP + Laravel)

## Goal
Prove behavior with fast, deterministic tests. Feature tests for HTTP/flow, unit tests for pure logic.

## Pest vs PHPUnit
Laravel 11 ships Pest by default; both run via `php artisan test`. Pest is terser; the assertions and
test database tooling are identical. Examples below use Pest with PHPUnit equivalents noted.

## Feature tests (HTTP boundary, DB, full flow)
Hit the route, assert status + JSON + DB state. Use `RefreshDatabase` to reset between tests.
```php
<?php

declare(strict_types=1);

use App\Models\User;
use function Pest\Laravel\{actingAs, postJson};

uses(Illuminate\Foundation\Testing\RefreshDatabase::class);

it('creates an order for an authenticated customer', function (): void {
    // Arrange
    $user = User::factory()->create();

    // Act
    $response = actingAs($user)->postJson('/api/v1/orders', [
        'customer_id' => $user->id,
        'items'       => [['sku' => 'ABC', 'qty' => 2]],
    ]);

    // Assert
    $response->assertCreated()
        ->assertJsonPath('data.status', 'pending');

    $this->assertDatabaseHas('orders', ['customer_id' => $user->id]);
});
```

## Unit tests (pure logic, no framework)
Test Actions/Services/enums in isolation, mocking collaborators.
```php
it('marks paid orders as final', function (): void {
    expect(OrderStatus::Paid->isFinal())->toBeTrue()
        ->and(OrderStatus::Pending->isFinal())->toBeFalse();
});
```

## RefreshDatabase
Migrates a fresh schema and wraps each test in a transaction that rolls back. Use a fast driver
(SQLite `:memory:` or a dedicated test DB) in `phpunit.xml`. For tests that need real persistence
across connections, use `DatabaseTransactions` or `DatabaseMigrations` instead.

## Mocking
Mock only true boundaries (external APIs, gateways). Prefer real objects + DB for everything else.
```php
$gateway = Mockery::mock(PaymentGateway::class);
$gateway->expects('charge')->once()->with(1_000)->andReturn(true);
$this->app->instance(PaymentGateway::class, $gateway);
```
Do not mock Eloquent models — use factories and the test database; mocking the ORM tests the mock,
not your code.

## Fakes (built-in test doubles)
Laravel provides fakes that record interactions without side effects. Swap them in, then assert.
```php
use Illuminate\Support\Facades\{Mail, Queue, Storage, Event, Bus, Notification};

Mail::fake();
Queue::fake();
Storage::fake('s3');

// ... exercise code ...

Mail::assertSent(OrderConfirmation::class);
Queue::assertPushed(ProcessOrder::class);
Storage::disk('s3')->assertExists('invoices/1.pdf');
Event::assertDispatched(OrderCreated::class);
```
Use `Http::fake([...])` to stub outbound HTTP and `Http::assertSent(...)` to verify calls.

## AAA structure
Arrange (factories, fakes, state) → Act (one call under test) → Assert (status, JSON, DB, fakes).
One logical behavior per test. Name tests as sentences: `it('rejects an order with no items')`.

## What to test
- Each endpoint: happy path, validation failure (422), unauthorized (403), not found (404).
- Each Action: success and each domain failure (exception thrown).
- Edge cases: empty collections, boundary numbers, enum transitions.

## Common risks
- Tests depending on execution order or leftover DB state (missing `RefreshDatabase`).
- Over-mocking — mocking Eloquent or the framework instead of using fakes/factories.
- Asserting only status code, ignoring body and persisted state.
- Real network/mail/queue side effects because a fake was not registered.

## Forbidden
- Hitting real external services in the test suite.
- Sharing mutable state between tests.
- Skipping tests for behavior changes ("I'll add them later").
