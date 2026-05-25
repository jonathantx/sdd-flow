---
name: php-laravel
version: 1.0.0
description: Implements changes in PHP + Laravel code (Laravel 11+, PHP 8.2+) using architecture, API, persistence, testing, security, observability and conventions references. Use when the task adds, fixes, refactors or validates Laravel code — controllers, Eloquent models, jobs, FormRequests, Policies, migrations. Do not use for non-PHP tasks or for legacy PHP without a Laravel application.
---

# PHP + Laravel Implementation

## When this is used (for a junior dev)
You loaded this because you are touching a Laravel app (you saw `artisan`, `composer.json` with `laravel/framework`, `app/`, `routes/`). It tells you HOW to structure code so it is testable, secure and idiomatic — not just "make it work".

## References (read only what the task needs)
- `references/architecture.md` — directory layout, Action/Service classes, DTOs, when to use repositories, going beyond plain MVC.
- `references/api.md` — routes, thin Controllers, FormRequest validation, API Resources, status codes, exception handling.
- `references/persistence.md` — Eloquent, migrations, relationships, fixing N+1 with eager loading, transactions, factories/seeders.
- `references/testing.md` — Pest/PHPUnit, feature vs unit, RefreshDatabase, mocking, fakes (Mail/Queue/Storage), AAA.
- `references/security.md` — mass assignment, Policies/Gates, validation, CSRF, secrets/.env, OWASP in Laravel.
- `references/observability.md` — logging channels, log context, Telescope, metrics, queue monitoring.
- `references/conventions.md` — PSR-12, Laravel naming, `declare(strict_types=1)`, typing, Pint, namespaces.

## Golden rules
- Always `declare(strict_types=1);` and type every parameter, property and return.
- Controllers stay thin: validate via FormRequest, delegate to an Action/Service, return a Resource.
- Never trust input — validate it; never use `Model::create($request->all())` without `$fillable`/`$guarded`.
- Authorize with Policies/Gates, not `if ($user->id === ...)` scattered in controllers.
- Fix N+1 with eager loading (`with()`); wrap multi-write operations in `DB::transaction()`.
- Keep secrets in `.env`, read through `config()` — never `env()` outside config files.
- Every behavior change ships with a test; format with `./vendor/bin/pint` before finishing.
