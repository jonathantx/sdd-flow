# Security (PHP + Laravel)

## Goal
Trust nothing from the client. Validate, authorize and isolate secrets by default.

## Mass assignment
An attacker can add fields you did not expect (`is_admin`, `role`) if you assign raw input.
Always restrict with `$fillable` (allow-list) or `$guarded` (deny-list).
```php
protected $fillable = ['name', 'email'];          // only these can be mass-assigned
// never: protected $guarded = []; on user-facing models
```
Never pass `$request->all()` into `create()`/`update()` — pass `$request->validated()` (only allowed
keys survive validation), and keep `$fillable` as a second gate.

## Authorization — Policies and Gates
Authorization is WHO-can-do-WHAT; it is separate from authentication (WHO-are-you) and validation
(IS-the-input-valid). Centralize it in Policies, not scattered `if` checks.
```php
final class OrderPolicy
{
    public function view(User $user, Order $order): bool
    {
        return $user->id === $order->customer_id;
    }

    public function update(User $user, Order $order): bool
    {
        return $user->id === $order->customer_id && ! $order->status->isFinal();
    }
}
```
Enforce it:
```php
$this->authorize('update', $order);          // controller — throws 403 if denied
Gate::authorize('update', $order);           // anywhere
$user->can('view', $order);                  // boolean check
abort_unless($user->can('view', $order), 403);
```
Use Gates for ability checks not tied to a model (`Gate::define('access-admin', ...)`).

## Validation
Every external input passes a FormRequest (see `api.md`). Validate type, presence, range, format and
existence (`exists:`, `unique:`). Reject unknown shapes rather than ignoring them.

## CSRF
`web` routes are CSRF-protected by default — keep the `@csrf` token in forms. `api` routes are
stateless and use token/bearer auth (Sanctum), so CSRF does not apply there. Do not disable CSRF on
web routes to "make it work".

## Authentication
Use Laravel Sanctum (SPA/token) or Passport (OAuth) — never roll your own. Hash with the framework
(`Hash::make`, `Hash::check`; bcrypt/argon2 by default). Never store plaintext or reversible secrets.
Rate-limit auth endpoints: `Route::middleware('throttle:5,1')`.

## Secrets and .env
Secrets live in `.env` (git-ignored), read only inside `config/*.php` via `env()`. Everywhere else use
`config('services.stripe.key')`. Calling `env()` outside config breaks once `config:cache` runs in
production. Never commit `.env`, API keys, or credentials; never log secret values.

## OWASP in a Laravel context
- **Injection:** use Eloquent / query builder bindings; never concatenate input into raw SQL or shell.
- **Broken access control:** Policies on every model action; verify ownership, not just authentication.
- **Sensitive data exposure:** shape responses with API Resources; `$hidden = ['password', ...]`.
- **XSS:** Blade `{{ }}` auto-escapes — use `{!! !!}` only on trusted, sanitized HTML.
- **SSRF / outbound:** validate and allow-list URLs before server-side HTTP requests.
- **File uploads:** validate `mimes`/`max`, store outside the webroot, never trust the filename.
- **Security misconfig:** `APP_DEBUG=false` and `APP_ENV=production` in prod; HTTPS enforced.
- **Vulnerable dependencies:** keep `composer.lock` current; run `composer audit`.

## Common risks
- Authorizing in the controller for one path but forgetting another (bulk endpoints, queue jobs).
- `$guarded = []` plus `create($request->all())` enabling privilege escalation.
- `env()` calls outside config breaking under `config:cache`.
- Returning models that expose `password`, tokens, internal flags.

## Forbidden
- Disabling CSRF on web routes or `APP_DEBUG=true` in production.
- Raw SQL built from request input.
- Committing secrets or logging credentials/tokens.
- Custom crypto/password hashing instead of framework primitives.
