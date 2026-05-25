---
name: react
version: 1.0.0
description: Implements UI changes in React (React 18/19 + TypeScript) using modern function components, hooks, typed props and proportional validation. Use when the task involves building, fixing, refactoring or testing React/TSX components, hooks, client/server state, accessibility or frontend tests. Do not use for non-React tasks or backend-only work.
---

# React Implementation

## When this is used (for a junior dev)
You are about to touch a React app written with TypeScript and function components.
Load only the references the task needs, follow the existing project style, and never invent APIs or props — check the code first.

## Procedure
1. Confirm the base load contract in `AGENTS.md` was fulfilled.
2. Read `package.json` to detect React version, bundler (Vite/Next/CRA), test runner and state/data libs.
3. Read only the references below that match the task. Do not load all of them.
4. Make the smallest safe change, type it strictly, add/adjust tests for behavior changes, then validate with the project scripts (`lint`, `test`, `typecheck`).

## References (load on demand)
- `references/architecture.md` — feature-based folders, composition, container vs presentational, colocation, when to extract a hook.
- `references/components.md` — function components, typed props, children patterns, controlled vs uncontrolled, refs.
- `references/state.md` — useState/useReducer, context, Zustand/Redux Toolkit/TanStack Query, server vs client state, derived state.
- `references/performance.md` — re-renders, memo/useMemo/useCallback (and when NOT to), code splitting, lazy, virtualization, keys, Suspense.
- `references/accessibility.md` — semantic HTML, ARIA, focus/keyboard, labels, contrast, accessible forms, a11y testing.
- `references/testing.md` — React Testing Library + Vitest/Jest, role queries, user-event, MSW, behavior over implementation.
- `references/conventions.md` — strict TS in React, naming, import order, styling (CSS Modules/Tailwind), avoiding anti-patterns.

## Golden rules
- Function components + hooks only. No class components in new code.
- Strict TypeScript: no `any` without justification; type props and hook returns explicitly.
- "You might not need useEffect" — derive during render, handle events in handlers.
- Server state belongs to a data lib (TanStack Query), not `useState` + `useEffect` + fetch.
- Stable, unique `key`s (never the array index for dynamic lists).
- Accessibility is not optional: semantic elements first, ARIA only when needed.

## Error handling
- If `package.json` is missing, stop before assuming React version or tooling.
- If a UI lib (MUI, Chakra, shadcn) is present, follow its component API instead of hand-rolling.
- On conflict with base governance, follow the safer constraint and record the assumption.
