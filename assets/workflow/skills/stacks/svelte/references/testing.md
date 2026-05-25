# Testing

Test **behavior**, not implementation. Use Vitest + `@testing-library/svelte` for components and
units, and Playwright for end-to-end flows. Pure logic in `$lib/utils` and `.svelte.ts` modules is
the cheapest to test — extract it from components.

## Setup

`@testing-library/svelte` works with Vitest in a browser-like environment (jsdom or, preferably, the
Vitest browser mode / `vitest-browser-svelte` for real DOM). Configure two projects: one for
component/browser tests, one for server/node tests.

```ts
// vite.config.ts (excerpt)
import { defineConfig } from 'vitest/config';
import { sveltekit } from '@sveltejs/kit/vite';

export default defineConfig({
  plugins: [sveltekit()],
  test: {
    projects: [
      { test: { name: 'client', environment: 'jsdom', include: ['src/**/*.svelte.test.ts'],
                setupFiles: ['./vitest-setup.ts'] } },
      { test: { name: 'server', environment: 'node', include: ['src/**/*.test.ts'],
                exclude: ['src/**/*.svelte.test.ts'] } }
    ]
  }
});
```

## Component tests (behavior-first)

Render, interact like a user, assert on what the user sees. Query by role/label, not by class.

```ts
// src/lib/components/Counter.svelte.test.ts
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { expect, test } from 'vitest';
import Counter from './Counter.svelte';

test('increments on click', async () => {
  const user = userEvent.setup();
  render(Counter, { props: { start: 2 } });

  const button = screen.getByRole('button', { name: /clicks/i });
  expect(button).toHaveTextContent('clicks: 2');

  await user.click(button);
  expect(button).toHaveTextContent('clicks: 3');
});
```

Verify a callback prop fires with the right payload (events are props in Svelte 5):

```ts
import { vi } from 'vitest';
test('emits onsearch with the query', async () => {
  const onsearch = vi.fn();
  const user = userEvent.setup();
  render(Search, { props: { onsearch } });

  await user.type(screen.getByLabelText('Search'), 'svelte');
  await user.click(screen.getByRole('button', { name: /search/i }));
  expect(onsearch).toHaveBeenCalledWith('svelte');
});
```

## Testing runes in `.svelte.ts`

Reactive modules can be tested in a `.svelte.test.ts` file (so the compiler processes runes). Wrap
effect-driven assertions in `$effect.root` to control lifecycle, or just assert deriveds directly.

```ts
// src/lib/state/cart.svelte.test.ts
import { flushSync } from 'svelte';
import { expect, test } from 'vitest';
import { createCart } from './cart.svelte';

test('total reflects added lines', () => {
  const cart = createCart();
  cart.add({ id: 'a', qty: 2, price: 5 });
  flushSync();
  expect(cart.total).toBe(10);
});
```

## Mocking `load` and server modules

Test `load` functions as plain functions — pass a fake `event`. Mock `$lib/server/*` and
`@sveltejs/kit` helpers (`error`, `redirect`) with `vi.mock`.

```ts
import { expect, test, vi } from 'vitest';
import { load } from './+page.server';

vi.mock('$lib/server/posts', () => ({
  getPost: vi.fn(async (slug: string) => ({ slug, title: 'Hi' }))
}));

test('load returns the post', async () => {
  const result = await load({ params: { slug: 'hi' } } as any);
  expect(result.post.title).toBe('Hi');
});
```

## End-to-end with Playwright

E2e covers real navigation, SSR, and form actions against a built app. Add via `sv add playwright`.

```ts
// e2e/blog.test.ts
import { expect, test } from '@playwright/test';

test('visitor reads a post', async ({ page }) => {
  await page.goto('/blog/hello-world');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Hello World');
});
```

## Guidelines

- Prefer role/label queries (`getByRole`, `getByLabelText`) — they also assert accessibility.
- Mock only true boundaries (network, DB, server modules); never mock the component under test.
- Keep tests deterministic: fake timers/clock for intervals, avoid real network.
- One behavior per test; name tests by the behavior, not the method.
