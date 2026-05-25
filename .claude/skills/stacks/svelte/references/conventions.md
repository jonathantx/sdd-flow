# Conventions

Consistency keeps a Svelte 5 + SvelteKit codebase predictable. Follow the existing project style
first; the defaults below apply when the project hasn't decided.

## TypeScript in `.svelte`

- Always `<script lang="ts">`. Enable `strict: true`; avoid `any` — prefer `unknown` and narrow.
- Type props with an `interface Props` and `let { ... }: Props = $props()`. Don't inline large prop
  types.
- Type snippets with `Snippet` / `Snippet<[Arg]>` from `'svelte'`.
- Use generated route types: `import type { PageProps, PageServerLoad, Actions } from './$types'`.
- Reuse DOM attribute types via `svelte/elements` (`HTMLButtonAttributes`, etc.) for wrapper components.
- Augment app types in `src/app.d.ts` (`App.Locals`, `App.PageData`, `App.Error`).

## Naming

- Components: `PascalCase.svelte` (`UserCard.svelte`).
- Reactive modules: `kebab-or-camel.svelte.ts` (the `.svelte.ts` suffix is required for runes).
- Plain utilities/types: `camelCase.ts` / `types.ts`.
- Route files keep their framework names (`+page.svelte`, `+page.server.ts`, `+layout.ts`, `+server.ts`).
- Callback props: `on<Event>` (`onclick`, `onsave`, `onselect`). Boolean props read as adjectives
  (`disabled`, `loading`, `selected`).

## `$lib` organization

```
$lib/
  components/   # reusable .svelte components (presentational)
  server/       # server-only modules (DB, secrets) — never imported client-side
  state/        # *.svelte.ts reactive logic / stores
  utils/        # pure framework-free TS
  types.ts      # shared types
```

Import via the `$lib` alias, not deep relative paths (`import Foo from '$lib/components/Foo.svelte'`).
Keep `server/` code out of client bundles — SvelteKit enforces this and it prevents secret leaks.

## Styling

- Default to component-scoped `<style>` blocks — styles are auto-scoped to the component, preventing
  leakage. Use `:global(...)` deliberately and sparingly.
- Use the `class:` directive and `class={...}` for conditional classes; `style:` for dynamic inline
  styles; CSS custom properties for theming.
- If the project uses Tailwind, prefer utility classes and keep `<style>` for the rare bespoke rule;
  don't mix two styling systems on the same element without reason.
- Global resets / tokens go in `src/app.css` imported from the root `+layout.svelte`.

```svelte
<div class:active={isActive} class="card" style:--accent={color}>…</div>
```

## Runes conventions

- Runes-only: `$state`, `$derived`, `$effect`, `$props`, `$bindable`. No `export let`, `$:`, `on:`,
  `createEventDispatcher`, or `<slot>`.
- Derive, don't sync: use `$derived`/`$derived.by`; reserve `$effect` for DOM/3rd-party/analytics.
- One source of truth per value. Lift shared reactive state into `$lib/state/*.svelte.ts` via getters.
- `$effect` always cleans up (return a teardown) and never writes state it also reads.

## Anti-patterns to avoid

- Module-level mutable state used during SSR (leaks across requests) — use `locals`/context/cookies.
- `{@html ...}` with unsanitized input (XSS) — sanitize first.
- `{#each}` without a stable key — causes DOM churn and state bugs on reorder.
- Putting secrets or DB calls in universal `load` (`+page.ts`) — use `+page.server.ts`.
- Overusing `$bindable` and context — prefer explicit props and callbacks for clear data flow.
- Silencing `svelte-check`/a11y warnings instead of fixing the cause.

## Script block order

Keep `<script>` contents in a predictable order so components stay scannable:

1. Imports (components, types, `$lib` utilities).
2. `interface Props` + `let { ... }: Props = $props()`.
3. Local `$state` declarations.
4. `$derived` values.
5. Functions / event handlers.
6. `$effect` blocks (last — side effects after the reactive graph is defined).

```svelte
<script lang="ts">
  import Child from '$lib/components/Child.svelte';
  import type { Snippet } from 'svelte';

  interface Props { items: string[]; children?: Snippet; }
  let { items, children }: Props = $props();

  let query = $state('');
  let filtered = $derived(items.filter((i) => i.includes(query)));

  function reset() { query = ''; }
</script>
```

## Tooling

Run `sv check` (svelte-check) for types + a11y, Prettier (`prettier-plugin-svelte`) for formatting,
and ESLint (`eslint-plugin-svelte`) for lint. Prefer the scripts already defined in `package.json`
(`npm run check`, `npm run lint`, `npm test`) before assuming commands. Add tooling with `sv add`
(e.g. `sv add tailwind vitest playwright eslint prettier`) rather than wiring configs by hand.
