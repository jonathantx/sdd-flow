# React Performance

Make the UI fast without prematurely optimizing. Measure first (React DevTools Profiler).

## How re-renders work
A component re-renders when its state changes, its parent re-renders, or its context value changes. A re-render is not inherently slow — React diffs and updates only what changed. Optimize only proven hotspots.

## memo / useMemo / useCallback — and when NOT to use them
These exist to skip work. They are not free: they add complexity and memory, and a wrong dependency array causes bugs.

- `React.memo(Component)` — skips re-render if props are shallow-equal. Use on a pure component that renders often with the same props.
- `useMemo(fn, deps)` — caches an expensive computation result.
- `useCallback(fn, deps)` — caches a function identity (useful when passing callbacks to memoized children or hook deps).

```tsx
const Row = React.memo(function Row({ item, onPick }: RowProps) {
  return <li onClick={() => onPick(item.id)}>{item.name}</li>;
});

function List({ items }: { items: Item[] }) {
  const onPick = useCallback((id: string) => console.log(id), []);
  const sorted = useMemo(() => [...items].sort((a, b) => a.name.localeCompare(b.name)), [items]);
  return <ul>{sorted.map((i) => <Row key={i.id} item={i} onPick={onPick} />)}</ul>;
}
```

Do NOT memoize when:
- The computation is cheap (string concat, small array map).
- The component rarely re-renders.
- Props change every render anyway (memo can't help).

> Note: with the React Compiler (React 19+), much manual memoization becomes unnecessary. Don't scatter `useMemo`/`useCallback` by default — reach for them only on measured hotspots.

## Stable keys
Keys let React match elements across renders. Use a stable id from the data. The array index is fine only for static, never-reordered lists; using it on a dynamic list causes wrong state association and subtle bugs.

```tsx
{users.map((u) => <UserCard key={u.id} user={u} />)}   // good
{users.map((u, i) => <UserCard key={i} user={u} />)}   // risky for dynamic lists
```

## Code splitting and lazy loading
Split large or rarely-used parts of the tree to shrink the initial bundle.

```tsx
import { lazy, Suspense } from "react";

const Dashboard = lazy(() => import("./Dashboard"));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <Dashboard />
    </Suspense>
  );
}
```

Split by route first (biggest win), then by heavy widgets (charts, editors).

## Suspense
`Suspense` shows a fallback while a child is loading (lazy component or a Suspense-enabled data source). Keep fallbacks lightweight and place boundaries where a loading state makes UX sense, not at the very top of the app.

## Virtualization
For long lists/tables (hundreds+ rows), render only visible rows with `@tanstack/react-virtual` or `react-window`. This keeps the DOM small.

```tsx
import { useVirtualizer } from "@tanstack/react-virtual";

function Rows({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);
  const v = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 40,
  });
  return (
    <div ref={parentRef} style={{ height: 400, overflow: "auto" }}>
      <div style={{ height: v.getTotalSize(), position: "relative" }}>
        {v.getVirtualItems().map((row) => (
          <div key={row.key} style={{ position: "absolute", top: row.start, height: row.size }}>
            {items[row.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Other quick wins
- Lift slow context consumers out, or split contexts, so they don't re-render the world.
- Push state down to the smallest component that needs it.
- Debounce/throttle high-frequency handlers (resize, search input).
- Avoid creating new object/array literals as props to memoized children every render.

## Don't optimize blind
Profile with React DevTools "Highlight updates" and the Profiler tab. Fix the component that actually shows up hot — not the one you guessed.
