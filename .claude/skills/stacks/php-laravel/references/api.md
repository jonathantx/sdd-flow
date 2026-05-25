# API (PHP + Laravel)

## Goal
Predictable HTTP boundaries: validate input, delegate logic, shape output, return correct status codes.

## Routes
Define routes in `routes/api.php` (stateless, no session/CSRF) or `routes/web.php`. Group by prefix,
middleware and version. Bind models with route-model binding.
```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function (): void {
    Route::apiResource('orders', OrderController::class);
    Route::post('orders/{order}/cancel', [OrderController::class, 'cancel']);
});
```
`{order}` is resolved to an `Order` model automatically; a missing id returns 404 before your code runs.

## Thin controllers
A controller method: receive a validated request, call one Action/Service, return a Resource.
No business rules, no query building.
```php
final class OrderController extends Controller
{
    public function store(CreateOrderRequest $request, CreateOrder $action): JsonResponse
    {
        $order = $action->handle(CreateOrderData::fromRequest($request));

        return OrderResource::make($order)
            ->response()
            ->setStatusCode(201);
    }

    public function show(Order $order): OrderResource
    {
        $this->authorize('view', $order);   // delegates to Policy

        return OrderResource::make($order->load('items'));
    }
}
```

## Validation with FormRequest
Never validate inline in controllers for non-trivial input. A FormRequest also handles authorization.
```php
final class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Order::class);
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'customer_id'     => ['required', 'integer', 'exists:customers,id'],
            'items'           => ['required', 'array', 'min:1'],
            'items.*.sku'     => ['required', 'string'],
            'items.*.qty'     => ['required', 'integer', 'min:1'],
        ];
    }
}
```
Failed validation returns 422 with a JSON error body automatically (for `expectsJson`/api requests).
Failed `authorize()` returns 403.

## API Resources (output shaping)
Never return raw models — they leak columns and break when the schema changes.
```php
final class OrderResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id'       => $this->id,
            'status'   => $this->status->value,
            'total'    => $this->total,
            'items'    => OrderItemResource::collection($this->whenLoaded('items')),
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
```
Use `whenLoaded()` so you never trigger a lazy query (N+1) inside serialization.

## Status codes
- `200` read/update success, `201` created, `204` deleted/no body.
- `401` unauthenticated, `403` authenticated but not allowed, `404` not found.
- `409` conflict (e.g. duplicate), `422` validation error, `429` rate-limited.
- `5xx` only for genuine server faults — never for expected business errors.

## Exception handling
Centralize in `bootstrap/app.php` (Laravel 11 replaces the old `Handler.php`). Map domain exceptions
to responses; do not leak stack traces or messages in production.
```php
// bootstrap/app.php
->withExceptions(function (Exceptions $exceptions): void {
    $exceptions->render(function (OrderNotPayableException $e, Request $request) {
        return response()->json(['message' => $e->getMessage()], 409);
    });

    $exceptions->render(function (ModelNotFoundException $e, Request $request) {
        if ($request->expectsJson()) {
            return response()->json(['message' => 'Resource not found'], 404);
        }
    });
})
```
Throw typed domain exceptions from Actions; let the handler translate them to HTTP.
```php
final class OrderNotPayableException extends \DomainException {}
```

## Common risks
- Returning Eloquent models directly (over-exposure, schema coupling, N+1 in serialization).
- Validating with `$request->validate([...])` inline instead of a reusable FormRequest.
- Catching exceptions in controllers and returning 200 with an error body.
- Building queries inside controllers.

## Forbidden
- Business logic in route closures.
- Returning `500` for predictable business outcomes.
- Exposing exception messages / stack traces to clients in production.
