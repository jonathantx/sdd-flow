# Accessibility

Svelte's compiler emits **a11y warnings** at build time (e.g. `a11y_click_events_have_key_events`,
`a11y_missing_attribute`, `a11y_label_has_associated_control`). Treat them as errors — fix the
underlying issue rather than disabling the warning. Run `svelte-check` / `sv check` in CI.

## Semantic HTML first

Prefer real elements over `div`/`span` with handlers. A `<button>` is focusable, keyboard-operable,
and announced correctly for free.

```svelte
<!-- WRONG: clickable div triggers a11y_click_events_have_key_events + a11y_no_static_element_interactions -->
<div onclick={open}>Open</div>

<!-- RIGHT -->
<button type="button" onclick={open}>Open</button>
```

Use `<nav>`, `<main>`, `<header>`, `<ul>/<li>`, `<h1>`–`<h6>` (in order) to convey structure. One
`<main>` per page, one `<h1>`.

## Labels & form controls

Every input needs an accessible name. Associate a `<label>` via `for`/`id`, or wrap the control.
`$props.id()` generates SSR-stable unique ids for linking.

```svelte
<script lang="ts">
  const uid = $props.id();
  let email = $state('');
</script>

<label for="{uid}-email">Email</label>
<input id="{uid}-email" type="email" bind:value={email}
       aria-describedby="{uid}-email-help" />
<p id="{uid}-email-help">We never share your email.</p>
```

For icon-only buttons, supply `aria-label`. For decorative images use `alt=""`; for meaningful ones,
describe them.

## Accessible forms & validation

- Mark required fields with `required` and reflect errors with `aria-invalid` + `aria-describedby`.
- Surface server validation (from form actions) into the DOM, and move focus or announce it.
- Use a live region for async status so screen readers hear it.

```svelte
<script lang="ts">
  import type { PageProps } from './$types';
  let { form }: PageProps = $props();
</script>

<form method="POST">
  <label for="email">Email</label>
  <input id="email" name="email" type="email"
         aria-invalid={form?.error ? 'true' : undefined}
         aria-describedby={form?.error ? 'email-error' : undefined} />
  {#if form?.error}
    <p id="email-error" role="alert">{form.error}</p>
  {/if}
  <button>Save</button>
</form>

<div aria-live="polite">{form?.success ? 'Saved' : ''}</div>
```

## Focus & keyboard

- All interactive UI must be reachable and operable by keyboard. Don't add `tabindex` > 0.
- Custom widgets (menus, dialogs, tabs) need the correct ARIA roles, keyboard handlers
  (Arrow/Escape/Enter), and focus management.
- Manage focus on route change and after opening dialogs; move focus into the dialog and trap it,
  return focus to the trigger on close. SvelteKit announces navigations to screen readers, but
  programmatic focus is still your responsibility for modals/SPA-like UI.

```svelte
<script lang="ts">
  let dialog = $state<HTMLDialogElement>();
  function open() { dialog?.showModal(); }   // <dialog> gives focus trap + Escape for free
</script>
<button onclick={open}>Open</button>
<dialog bind:this={dialog}>
  <button onclick={() => dialog?.close()}>Close</button>
</dialog>
```

## Motion & contrast

- Respect reduced motion: gate non-essential transitions on the media query.

```svelte
<script lang="ts">
  import { MediaQuery } from 'svelte/reactivity';
  const reduce = new MediaQuery('(prefers-reduced-motion: reduce)');
</script>
{#if !reduce.current}<div transition:fade>…</div>{:else}<div>…</div>{/if}
```

- Meet WCAG AA contrast (4.5:1 body text, 3:1 large text / UI). Never convey state by color alone —
  pair with text or icons. Ensure visible focus styles (don't remove `outline` without a replacement).
