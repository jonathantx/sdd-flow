# State with Runes

Svelte 5 reactivity is built on **runes**. Use `$state` for sources of truth, `$derived` for
computed values, and `$effect` only as an escape hatch for side effects.

## `$state` — reactive source of truth

`count` is just a value; mutate it directly. Objects and arrays become deeply reactive proxies, so
`array.push(...)` and `obj.field = x` trigger fine-grained updates.

```svelte
<script lang="ts">
  let count = $state(0);
  let todos = $state<{ text: string; done: boolean }[]>([]);

  function addTodo(text: string) { todos.push({ text, done: false }); }
</script>

<button onclick={() => count++}>clicks: {count}</button>
```

Use `$state.raw(...)` for large objects/arrays you only ever replace (reassign), never mutate — it
skips proxy overhead. Use `$state.snapshot(value)` when passing reactive state to a non-Svelte API
(`structuredClone`, charting libs) that does not expect a Proxy.

In classes, mark fields with `$state`:

```ts
class Counter {
  count = $state(0);
  double = $derived(this.count * 2);
  increment = () => { this.count++; };  // arrow keeps `this`
}
```

## `$derived` — computed values

`$derived(expr)` recomputes when its tracked dependencies change. The expression must be
side-effect-free. For multi-statement logic use `$derived.by(() => { ... })`.

```svelte
<script lang="ts">
  let items = $state([{ price: 2, qty: 3 }]);
  let total = $derived.by(() => items.reduce((s, i) => s + i.price * i.qty, 0));
  let label = $derived(`Total: ${total}`);
</script>
```

Deriveds skip downstream updates when the recomputed value is referentially identical, which is the
core of Svelte's efficiency. You may reassign a derived for optimistic UI (Svelte 5.25+) and it will
reset when dependencies change.

## `$effect` — side effects only

`$effect` runs after mount and after dependency changes; it is for canvas drawing, third-party
libraries, analytics, or manual DOM work. Return a teardown function for cleanup. It runs in the
browser only (not during SSR).

```svelte
<script lang="ts">
  let ms = $state(1000);
  let count = $state(0);

  $effect(() => {
    const id = setInterval(() => count++, ms);
    return () => clearInterval(id);  // cleanup before re-run / on destroy
  });
</script>
```

### Avoid `$effect` for deriving/synchronizing state

Do **not** assign state inside `$effect` to mirror other state — use `$derived`.

```svelte
<!-- WRONG: effect that syncs state -->
let doubled = $state();
$effect(() => { doubled = count * 2; });

<!-- RIGHT -->
let doubled = $derived(count * 2);
```

For two linked inputs, use callback handlers or function bindings instead of cross-effects, which
risk infinite loops. Reserve `$effect` for genuine outside-world side effects.

## Shared reactive state — `.svelte.ts` modules

Runes work in `.svelte.ts` / `.svelte.js` files. You cannot export a reassigned `$state` directly;
export an object you mutate, or expose getter functions.

```ts
// $lib/state/cart.svelte.ts
interface Line { id: string; qty: number; price: number; }

function createCart() {
  let lines = $state<Line[]>([]);
  const total = $derived(lines.reduce((s, l) => s + l.qty * l.price, 0));

  return {
    get lines() { return lines; },
    get total() { return total; },
    add(line: Line) { lines.push(line); },
    clear() { lines = []; }
  };
}

export const cart = createCart();
```

```svelte
<script lang="ts">
  import { cart } from '$lib/state/cart.svelte.ts';
</script>
<p>Total: {cart.total}</p>
```

Note: a module-level singleton like this is fine on the **client**, but on the server it is shared
across requests — never store per-user data this way during SSR. For request-scoped shared state,
use Svelte `setContext`/`getContext` (set in a layout, read in descendants).

## Server state: `load` and form actions

Data from the network/DB belongs in `load`, surfaced as `data`. Mutations belong in form actions
(`+page.server.ts`), surfaced as `form`. Reactive props update automatically when `data`/`form`
change after navigation or submission.

```ts
// +page.server.ts
import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';

export const actions = {
  default: async ({ request }) => {
    const data = await request.formData();
    const email = data.get('email');
    if (typeof email !== 'string' || !email.includes('@')) {
      return fail(400, { email, error: 'Invalid email' });
    }
    // ...persist...
    return { success: true };
  }
} satisfies Actions;
```

Progressively enhance with `use:enhance` from `$app/forms` so submission works without a full
reload. Keep validation on the server (the source of truth); mirror client-side for UX only.
