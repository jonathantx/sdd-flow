# SvelteKit Architecture

SvelteKit is a filesystem-router meta-framework over Svelte 5. Routes live in `src/routes/`,
reusable code in `src/lib/` (aliased as `$lib`). Files prefixed with `+` are framework files.

## Project layout

```
src/
  routes/
    +layout.svelte          # root shell (shared UI, applies to all child routes)
    +layout.ts              # layout-level load (runs on server + client)
    +page.svelte            # the / page UI
    +page.ts                # universal load for /
    blog/
      +page.svelte
      +page.server.ts       # server-only load (DB, secrets) for /blog
      [slug]/
        +page.svelte        # dynamic route /blog/:slug
        +page.server.ts
    api/
      health/+server.ts     # JSON endpoint (GET/POST handlers)
  lib/
    components/             # reusable .svelte components
    server/                 # server-only modules (never shipped to client)
    state/                  # .svelte.ts reactive modules / stores
    utils/                  # pure TS helpers
  hooks.server.ts           # request interception (auth, locals)
  app.d.ts                  # App.Locals / App.PageData type augmentation
  app.css
svelte.config.js            # adapter + preprocess config
vite.config.ts
```

## Routing files (the `+` files)

- `+page.svelte` — the page component. Receives `data` (from `load`) and `form` (from actions) via `$props`.
- `+page.ts` — **universal** `load`: runs on the server during SSR, then on the client during navigation.
- `+page.server.ts` — **server** `load` and `actions`: runs only on the server. Use for DB access and secrets.
- `+layout.svelte` / `+layout(.server).ts` — shared UI + data for a route subtree. Render children via `{@render children()}`.
- `+server.ts` — standalone API route exporting `GET`, `POST`, etc. returning `Response`/`json(...)`.
- `+error.svelte` — error boundary for a route subtree.

## Load functions and data flow

`load` returns serializable data exposed to the page as `data`. Types are generated into `./$types`.

```ts
// src/routes/blog/[slug]/+page.server.ts
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getPost } from '$lib/server/posts';

export const load: PageServerLoad = async ({ params }) => {
  const post = await getPost(params.slug);
  if (!post) error(404, 'Not found');
  return { post }; // -> available as `data.post` in +page.svelte
};
```

```svelte
<!-- src/routes/blog/[slug]/+page.svelte -->
<script lang="ts">
  import type { PageProps } from './$types';
  let { data }: PageProps = $props();
</script>

<article>
  <h1>{data.post.title}</h1>
  {@html data.post.html}
</article>
```

Prefer server `load` for anything touching a database, filesystem, or secret. Use universal `load`
(`+page.ts`) only for data safe to run in the browser (e.g. public `fetch` with the provided `fetch`).

## UI / logic separation

- `.svelte` files: presentation, bindings, template logic. Keep them thin.
- `$lib/server/*`: server-only code. Importing these from client code is a build error — that is the
  guardrail that prevents leaking secrets.
- `$lib/state/*.svelte.ts`: reusable reactive logic (runes outside components). See `state.md`.
- `$lib/utils/*`: pure, framework-free TypeScript. Easiest to unit test.

## Stores vs runes (when to use which)

Svelte 5 reactivity is **runes-first**. Reach for runes by default; stores remain for specific cases.

- Component-local reactive state → `$state` / `$derived` inside the component.
- Shared reactive state across components → a `.svelte.ts` module exporting getters (see `state.md`).
- `$app/state` (`page`, `navigating`) → SvelteKit's runes-based app state. Prefer over the legacy
  `$app/stores`.
- Classic `writable`/`readable` stores from `svelte/store` → still valid for stream-like sources
  (RxJS interop, manual subscription control) or libraries that expect the store contract. Avoid
  using global stores for plain shared state — `.svelte.ts` runes are simpler and typed.

## SSR caution: no module-level mutable state

On the server, modules are shared across requests. Never store per-user/request data in a
module-level variable — it leaks between users. Keep request state in `event.locals` (set in
`hooks.server.ts`), in `load` return values, or in cookies/session.
