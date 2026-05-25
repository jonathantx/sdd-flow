# Observability (PHP + Laravel)

## Goal
When something breaks in production you can answer "what happened, to whom, and why" from logs and
metrics — without a debugger.

## Logging — channels (Monolog)
Laravel wraps Monolog. Channels are configured in `config/logging.php` (stack, single, daily, slack,
syslog, stderr). In containers prefer `stderr` so the platform collects logs.
```php
use Illuminate\Support\Facades\Log;

Log::info('Order created', ['order_id' => $order->id, 'total' => $order->total]);
Log::warning('Payment retry', ['attempt' => $attempt]);
Log::error('Payment failed', ['order_id' => $order->id, 'exception' => $e->getMessage()]);

// Route a specific concern to its own channel
Log::channel('billing')->info('Invoice issued', ['invoice_id' => $id]);
```
Pick levels deliberately: `debug` (dev detail), `info` (business events), `warning` (recoverable),
`error` (a request/job failed), `critical` (system-wide). Do not log at `error` for expected outcomes.

## Structured context
Pass context as the second array argument — never string-concatenate values into the message; that
breaks log search and aggregation. Attach request-scoped context once so every line carries it.
```php
Log::withContext(['request_id' => $requestId, 'user_id' => $user?->id]);
```
Use the `json` formatter in production so logs are machine-parseable. Never log secrets, tokens, full
card numbers, or passwords — scrub PII.

## Telescope (local/staging insight)
`laravel/telescope` records requests, queries, jobs, exceptions, mail, cache and more in a dashboard.
Invaluable for spotting N+1 queries and slow requests. Gate it so it is NOT exposed in production
(authorize in `TelescopeServiceProvider::gate()`), or disable it there entirely.

## Metrics
Laravel has no built-in metrics endpoint. Standard approach: expose Prometheus metrics
(e.g. a `/metrics` route via a package) or push to a StatsD/OTel collector. Track:
- HTTP request rate, latency, error rate per route.
- Queue: jobs processed, failed, wait time.
- Domain counters (orders created, payments failed).
Increment from Actions/listeners, not controllers, so background flows are counted too.

## Queue monitoring
Failed jobs land in the `failed_jobs` table — inspect with `php artisan queue:failed`, retry with
`queue:retry`. Configure backoff and `$tries` per job; send permanent failures to an alert channel via
the job's `failed()` method.
```php
final class ProcessOrder implements ShouldQueue
{
    public int $tries = 3;
    public array $backoff = [10, 30, 60];

    public function handle(): void { /* ... */ }

    public function failed(\Throwable $e): void
    {
        Log::critical('ProcessOrder permanently failed', ['error' => $e->getMessage()]);
    }
}
```
Run Horizon (`laravel/horizon`) for Redis queues to get throughput, wait-time and failure dashboards
plus alerting. Monitor worker liveness so a dead worker does not silently stall the queue.

## Tracing / correlation
Generate or accept a request id (middleware), put it in log context, and propagate it as a header to
downstream services and onto dispatched jobs so a single flow is traceable end to end.

## Health checks
Expose a lightweight `/up` endpoint (Laravel 11 ships one) for liveness probes, and a deeper
readiness check that verifies the DB, cache and queue connections before reporting healthy. Keep the
liveness check dependency-free so a slow downstream does not get your process killed by the orchestrator.

## Common risks
- Unstructured logs (`Log::info("order $id created")`) that cannot be filtered or aggregated.
- Logging secrets/PII.
- Telescope left enabled and unguarded in production (data exposure + overhead).
- Silent queue failures because `failed_jobs` and worker health are never watched.

## Forbidden
- Logging credentials, tokens, or raw PII.
- Using `error`/`critical` levels for normal business outcomes (noise hides real incidents).
- Shipping debug-level verbosity or Telescope to production.
