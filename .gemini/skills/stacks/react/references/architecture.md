# React Architecture

How to organize a React + TypeScript codebase so features stay isolated and code is easy to find.

## Feature-based folders
Group by feature, not by file type. A `components/` + `hooks/` + `utils/` split at the root does not scale.

```
src/
  features/
    checkout/
      components/        # UI used only by checkout
      hooks/             # useCheckout, useCart
      api/               # query/mutation functions
      types.ts
      index.ts           # public surface of the feature
    auth/
      ...
  components/            # shared, app-wide presentational UI (Button, Modal)
  hooks/                 # shared hooks (useDebounce, useMediaQuery)
  lib/                   # framework-agnostic helpers, api client
  app/                   # routing, providers, layout
  main.tsx
```

Rules:
- A feature folder owns its components, hooks, and API calls (colocation).
- Cross-feature imports go through the feature's `index.ts`, never deep paths.
- Truly shared UI moves up to `src/components`; if only one feature uses it, keep it inside the feature.

## Colocation
Keep related files next to each other: test, styles, and types live beside the component.

```
Button/
  Button.tsx
  Button.module.css
  Button.test.tsx
  index.ts
```

## Container vs presentational
A modern, light version of this split: keep data-fetching/state in one component and render via a "dumb" component that only takes props. Do not over-apply it.

```tsx
// container: owns data + handlers
function UserListContainer() {
  const { data, isLoading } = useUsers();
  if (isLoading) return <Spinner />;
  return <UserList users={data} onSelect={handleSelect} />;
}

// presentational: pure, easy to test and reuse
type UserListProps = { users: User[]; onSelect: (id: string) => void };
function UserList({ users, onSelect }: UserListProps) {
  return (
    <ul>
      {users.map((u) => (
        <li key={u.id}>
          <button onClick={() => onSelect(u.id)}>{u.name}</button>
        </li>
      ))}
    </ul>
  );
}
```

## Composition over configuration
Prefer composing components with `children` and slots over a single component with dozens of boolean props.

```tsx
// Good: composition
<Card>
  <Card.Header>Title</Card.Header>
  <Card.Body>Content</Card.Body>
</Card>

// Avoid: prop explosion
<Card title="Title" body="Content" hasHeader hasBorder size="lg" />
```

## When to extract a custom hook
Extract a hook when stateful logic is reused, or when a component mixes too many concerns. A hook is "just a function that calls other hooks".

Extract when:
- The same `useState`/`useEffect` block appears in 2+ components.
- A component body has more logic than JSX.
- You want to unit-test logic without rendering UI.

```tsx
function useDebouncedValue<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}
```

Do NOT extract a hook just to wrap a single `useState` — that adds indirection with no gain.

## Providers and app shell
Keep cross-cutting providers (router, query client, theme) at the top in `src/app`.

```tsx
function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>{children}</ThemeProvider>
    </QueryClientProvider>
  );
}
```

## Boundaries
- UI components never call `fetch` directly — they call hooks/feature `api/` functions.
- Domain types live in `types.ts`, not scattered inline.
- Avoid `utils/` dumping grounds; name modules by purpose (`formatDate.ts`, `money.ts`).
