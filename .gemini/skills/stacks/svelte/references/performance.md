# Performance

Svelte compiles components to small, surgical DOM updates — there is no virtual DOM diff. Most
performance wins come from working *with* the fine-grained reactivity, loading less, and loading it
at the right time.

## Fine-grained reactivity

Svelte tracks exactly which state each piece of the template reads and updates only those nodes.
You rarely need manual memoization. Keep state granular: separate independent values into separate
`$state` declarations rather than one big object, so unrelated updates don't invalidate together.

## `$derived` vs recomputation

Compute in `$derived`/`$derived.by`, not inline in the template, when the result is reused or
expensive. Deriveds cache and only recompute when dependencies change; if the new value is
referentially equal to the old one, downstream updates are skipped.

```svelte
<script lang="ts">
  let query = $state('');
  let items = $state<Item[]>([]);
  // recomputed only when query or items change
  let results = $derived.by(() =>
    items.filter((i) => i.name.toLowerCase().includes(query.toLowerCase()))
  );
</script>

<ul>{#each results as r (r.id)}<li>{r.name}</li>{/each}</ul>
```

Always key `{#each}` blocks with a stable id (`(item.id)`) so Svelte reuses DOM nodes on reorder
instead of recreating them.

## Avoid wasted work

- Don't put expensive logic in `$effect` to mirror state — use `$derived` (avoids extra render passes).
- Use `$state.raw` for large immutable datasets you only replace, skipping deep-proxy overhead.
- Pass `$state.snapshot` to external libraries to avoid proxy traps firing on every property read.
- Avoid recreating arrays/objects in the template on each render; compute once in a derived.

## Lazy loading & code splitting

SvelteKit code-splits per route automatically. For heavy widgets used conditionally, dynamic-import
the component so it isn't in the initial bundle.

```svelte
<script lang="ts">
  let Editor = $state<typeof import('$lib/components/Editor.svelte').default>();
  async function openEditor() {
    Editor = (await import('$lib/components/Editor.svelte')).default;
  }
</script>

{#if Editor}<Editor />{/if}
<button onclick={openEditor}>Edit</button>
```

## Prefetching & navigation

SvelteKit preloads route code and `load` data on link hover/touch by default. Tune it with
`data-sveltekit-preload-data`:

```svelte
<a href="/dashboard" data-sveltekit-preload-data="hover">Dashboard</a>
```

Use `"tap"` for low-value or expensive routes, `"hover"` (default) for most, and call
`preloadData(url)` from `$app/navigation` to warm a route before a programmatic navigation.

## Load strategy

- Return promises from `load` and `await` them in the template with `{#await}` to stream non-critical
  data without blocking the page (streaming server `load`).
- Use `depends`/`invalidate` to refetch only the `load` functions that changed, not the whole page.
- Prerender static pages with `export const prerender = true` to ship HTML with zero runtime cost.

## Transitions & animation

Built-in transitions (`transition:`, `in:`/`out:`, `animate:`) are GPU-friendly and tree-shakable —
only imported easings/transitions ship. Respect `prefers-reduced-motion` (see `accessibility.md`).
Keep transition durations short on large lists; combine `animate:flip` with keyed `{#each}` for
smooth reordering without layout thrash.
