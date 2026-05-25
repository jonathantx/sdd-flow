# Svelte 5 Components

A component is a `.svelte` file with optional `<script lang="ts">`, markup, and `<style>`. Use
**runes** — never legacy `export let`, `$:`, `on:`, or `<slot>`.

## Props with `$props` and types

Declare a `Props` interface and destructure. Fallback values are written in the destructuring.

```svelte
<!-- $lib/components/Avatar.svelte -->
<script lang="ts">
  interface Props {
    src: string;
    alt: string;
    size?: number;          // optional with default below
    rounded?: boolean;
  }

  let { src, alt, size = 40, rounded = true }: Props = $props();
</script>

<img {src} {alt} width={size} height={size} class:rounded />

<style>
  .rounded { border-radius: 50%; }
</style>
```

Rest props forward unknown attributes to an element:

```svelte
<script lang="ts">
  import type { HTMLButtonAttributes } from 'svelte/elements';
  interface Props extends HTMLButtonAttributes { loading?: boolean; }
  let { loading = false, children, ...rest }: Props = $props();
</script>

<button disabled={loading} {...rest}>{@render children?.()}</button>
```

## Snippets replace slots

Snippets are reusable markup blocks (`{#snippet}`) rendered with `{@render}`. They are passed to
components as props — typed with `Snippet` from `'svelte'`. Content placed between component tags
becomes the implicit `children` snippet.

```svelte
<!-- $lib/components/Card.svelte -->
<script lang="ts">
  import type { Snippet } from 'svelte';
  interface Props {
    title: string;
    children: Snippet;          // default slot content
    actions?: Snippet;          // named, optional
  }
  let { title, children, actions }: Props = $props();
</script>

<section class="card">
  <header>{title}</header>
  <div class="body">{@render children()}</div>
  {#if actions}<footer>{@render actions()}</footer>{/if}
</section>
```

```svelte
<!-- usage -->
<script lang="ts">
  import Card from '$lib/components/Card.svelte';
</script>

<Card title="Profile">
  <p>Body content becomes the `children` snippet.</p>
  {#snippet actions()}
    <button onclick={() => save()}>Save</button>
  {/snippet}
</Card>
```

Snippets can take parameters — ideal for list/row rendering:

```svelte
<script lang="ts">
  import type { Snippet } from 'svelte';
  interface Props<T> { items: T[]; row: Snippet<[T]>; }
  let { items, row }: Props<{ id: string }> = $props();
</script>

<ul>{#each items as item (item.id)}<li>{@render row(item)}</li>{/each}</ul>
```

## Events are callback props

There is no `createEventDispatcher` in idiomatic Svelte 5. Pass callbacks as props named `on<Event>`.

```svelte
<!-- Search.svelte -->
<script lang="ts">
  interface Props { onsearch: (query: string) => void; }
  let { onsearch }: Props = $props();
  let query = $state('');
</script>

<form onsubmit={(e) => { e.preventDefault(); onsearch(query); }}>
  <input bind:value={query} aria-label="Search" />
</form>
```

DOM events use lowercase attribute syntax (`onclick`, `oninput`, `onkeydown`) — not `on:click`.

## Bindings

`bind:` enables two-way binding to form controls and to `$bindable` props.

```svelte
<script lang="ts">
  let name = $state('');
  let agreed = $state(false);
  let el = $state<HTMLInputElement>();   // bind:this for element refs
</script>

<input bind:value={name} bind:this={el} />
<input type="checkbox" bind:checked={agreed} />
```

For a custom input component to be bindable, mark the prop `$bindable`:

```svelte
<!-- FancyInput.svelte -->
<script lang="ts">
  let { value = $bindable('') }: { value?: string } = $props();
</script>
<input bind:value />
<!-- parent: <FancyInput bind:value={message} /> -->
```

Use `$bindable` sparingly — prefer callback props for clear one-way data flow.

## Composition

Compose with snippets and small focused components. Avoid prop drilling deep trees — use
`setContext`/`getContext` for ambient values (theme, current user), and keep shared *reactive* state
in a `.svelte.ts` module (see `state.md`). Keep components presentational; push data fetching to
`load` and business logic to `$lib`.
