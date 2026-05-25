---
name: svelte
version: 1.0.0
description: Activate when implementing, fixing, refactoring, or reviewing frontend code on a Svelte 5 + SvelteKit + TypeScript stack — components, runes-based state, routing, load functions, form actions, accessibility, styling, or tests (Vitest/Playwright). Do not use for non-Svelte frontends (React/Vue) or backend-only tasks.
---

# Svelte 5 + SvelteKit Implementation

## When this is used

Use this skill any time the task touches a Svelte 5 UI built with SvelteKit and TypeScript: building
a `.svelte` component, wiring reactive state with runes, loading data with `load`, handling forms,
fixing a11y warnings, styling, or adding tests. It keeps implementation correct, typed, and idiomatic.

## References

Load only what the task needs.

- `references/architecture.md` — SvelteKit layout (routes, `$lib`, `+page`/`+layout`, `load`), UI/logic separation, stores vs runes.
- `references/components.md` — Svelte 5 components, `$props` with types, snippets, bindings, events as callbacks, composition.
- `references/state.md` — runes (`$state`, `$derived`, `$effect`), `.svelte.ts` stores, server state via `load`/form actions, avoiding `$effect`.
- `references/performance.md` — fine-grained reactivity, `$derived` vs recomputation, lazy loading, prefetch, transitions, avoiding wasted work.
- `references/accessibility.md` — Svelte a11y warnings, semantics, focus/keyboard, labels, accessible forms, contrast.
- `references/testing.md` — Vitest + `@testing-library/svelte`, behavior-first tests, Playwright e2e, mocking `load`.
- `references/conventions.md` — TS in `.svelte`, naming, `$lib` organization, scoped styles/Tailwind, runes conventions, anti-patterns.

## Golden rules

- Always use Svelte 5 runes (`$state`, `$derived`, `$effect`, `$props`). Never use legacy `export let` or `$:` reactive statements.
- Derive, don't synchronize: prefer `$derived`/`$derived.by` over `$effect` that assigns state. `$effect` is an escape hatch for DOM/3rd-party/analytics only.
- Pass events as callback props (`onclick`, `onsave`), not `createEventDispatcher`. Use snippets/`{@render}`, not legacy `<slot>`.
- Type props with an `interface Props` and `let { ... }: Props = $props()`. Type snippet props with `Snippet` from `'svelte'`.
- Load data in `load` (`+page.ts`/`+page.server.ts`); use server `load`/form actions for secrets and writes. Never put secrets in universal `load`.
- Keep components presentational; put reusable reactive logic in `.svelte.ts` modules under `$lib`. Avoid global mutable state on the server (SSR leaks).
- Respect a11y: real semantic elements, labelled controls, keyboard support. Never silence a11y warnings without a justified fix.
- Read `package.json`, `svelte.config.js`, and `tsconfig.json` before assuming versions, adapter, or tooling.
