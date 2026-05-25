# React Conventions

Consistent style for a React + TypeScript codebase. Match the existing project first; use these where the project is silent.

## Strict TypeScript in React
- Enable `strict: true` in `tsconfig.json`. No implicit `any`.
- Type props with `type`/`interface`; type hook return values explicitly when non-trivial.
- Avoid `any`; prefer `unknown` + narrowing. Avoid non-null `!` unless truly safe.
- Type event handlers with the right event type.

```tsx
const onChange = (e: React.ChangeEvent<HTMLInputElement>) => setValue(e.target.value);
const onSubmit = (e: React.FormEvent<HTMLFormElement>) => { e.preventDefault(); };
```

Use discriminated unions for variant props instead of many optional booleans.

```tsx
type AlertProps =
  | { kind: "info"; message: string }
  | { kind: "error"; message: string; retry: () => void };
```

## Naming
- Components: `PascalCase` (`UserCard`), file matches component name (`UserCard.tsx`).
- Hooks: `useCamelCase`, always starting with `use` (`useUserCart`).
- Booleans: `isLoading`, `hasError`, `canEdit`.
- Event handlers: `handleClick` locally; `onClick`/`onSelect` for props.
- Types: `PascalCase`; props type `XxxProps`.

## File and folder structure
- One main component per file; colocate its test and styles (see `architecture.md`).
- Barrel `index.ts` exports a feature's public surface; avoid deep cross-feature imports.

## Import order
Group and separate imports: external, then internal/aliased, then relative, then styles.

```tsx
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import { Button } from "@/components/Button";
import { useCart } from "@/features/cart";

import { formatPrice } from "./utils";
import styles from "./Cart.module.css";
```

Use path aliases (`@/`) over `../../../`. Configure in `tsconfig.json` + bundler.

## Styling
Pick one approach and stay consistent.
- **CSS Modules**: scoped classes, zero runtime, great default.
  ```tsx
  import styles from "./Card.module.css";
  <div className={styles.card} />;
  ```
- **Tailwind**: utility classes; extract repeated patterns into components, not `@apply` soup. Use `clsx`/`cn` for conditional classes.
  ```tsx
  <button className={cn("rounded px-3 py-2", isActive && "bg-blue-600 text-white")} />
  ```
- Keep design tokens (colors, spacing) centralized; avoid magic values scattered inline.

## "You might not need useEffect"
The most common React anti-pattern. Effects are for synchronizing with external systems (DOM, network subscription, non-React widgets) — not for reacting to props/state.

```tsx
// Bad: deriving state in an effect
useEffect(() => { setFullName(`${first} ${last}`); }, [first, last]);

// Good: derive during render
const fullName = `${first} ${last}`;

// Bad: handling an event in an effect
useEffect(() => { if (submitted) postData(); }, [submitted]);

// Good: do it in the handler
const handleSubmit = () => postData();
```

Legit effect uses: subscriptions, manual DOM/3rd-party widget setup, syncing to localStorage, fetching only when no data lib is available (prefer TanStack Query — see `state.md`). Always return a cleanup function for subscriptions/timeouts.

## Other anti-patterns to avoid
- Defining components inside render bodies (remounts each render).
- Index as `key` on dynamic lists.
- Mutating state/props directly (`arr.push(x)` then `setArr(arr)`).
- Overusing context for fast-changing values.
- Premature `useMemo`/`useCallback` everywhere (see `performance.md`).
- `useState` + `useEffect` + `fetch` for server data.

## Linting and formatting
- ESLint with `eslint-plugin-react-hooks` (enforces hook rules) and `eslint-plugin-jsx-a11y`.
- Prettier for formatting; do not hand-format.
- Respect the project's existing config; run `lint`, `typecheck`, and `test` before finishing.
