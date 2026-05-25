# React State Management

Choosing the right place and tool for each kind of state.

## The state hierarchy (try in order)
1. Local component state (`useState` / `useReducer`).
2. Lift state to the closest common parent.
3. React Context for low-frequency global values (theme, auth, locale).
4. A client-state library (Zustand / Redux Toolkit) for complex shared client state.
5. A server-state library (TanStack Query) for anything that comes from an API.

Most apps need far less global state than they think. Start local.

## useState vs useReducer
Use `useState` for independent values. Use `useReducer` when next state depends on previous state, or when multiple values change together.

```tsx
type State = { count: number; step: number };
type Action = { type: "inc" } | { type: "setStep"; step: number };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case "inc": return { ...state, count: state.count + state.step };
    case "setStep": return { ...state, step: action.step };
  }
}

const [state, dispatch] = useReducer(reducer, { count: 0, step: 1 });
```

## Derived state — do not store it
If a value can be computed from existing state/props, compute it during render. Storing it creates two sources of truth that drift.

```tsx
// Bad: redundant state + effect to sync
const [items, setItems] = useState<Item[]>([]);
const [count, setCount] = useState(0);
useEffect(() => setCount(items.length), [items]); // unnecessary

// Good: derive
const count = items.length;
const total = useMemo(() => items.reduce((s, i) => s + i.price, 0), [items]);
```

## When to use Context
Context is for values that rarely change and are needed deep in the tree. It is not a state manager — every consumer re-renders when the value changes.

```tsx
const ThemeContext = createContext<"light" | "dark">("light");

function useTheme() {
  return useContext(ThemeContext);
}
```

Avoid putting fast-changing state (form fields, mouse position) in context. Split contexts so unrelated consumers don't re-render.

## Client-state libraries
- **Zustand**: minimal, no boilerplate, no provider. Good default for shared client state.
- **Redux Toolkit**: structured, devtools, middleware; good for large apps with complex flows.

```tsx
// Zustand
import { create } from "zustand";

type CartState = {
  items: Item[];
  add: (item: Item) => void;
};

const useCart = create<CartState>((set) => ({
  items: [],
  add: (item) => set((s) => ({ items: [...s.items, item] })),
}));

// usage — selector subscribes only to what it reads
const items = useCart((s) => s.items);
```

## Server state belongs to a data lib
Data from an API is **server state**: it's cached, can go stale, and needs loading/error handling. Do not manage it with `useState` + `useEffect` + `fetch`. Use TanStack Query (or RTK Query).

```tsx
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

function useUsers() {
  return useQuery({
    queryKey: ["users"],
    queryFn: () => fetch("/api/users").then((r) => r.json() as Promise<User[]>),
  });
}

function useCreateUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: NewUser) =>
      fetch("/api/users", { method: "POST", body: JSON.stringify(body) }).then((r) => r.json()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["users"] }),
  });
}
```

This gives you caching, refetch, dedup, retries, and stale handling for free — things hand-rolled effects get wrong.

## Server vs client state, side by side
| Server state | Client state |
|---|---|
| Users, products, orders | Modal open, selected tab, form draft |
| Lives on a server, async | Lives only in the UI, sync |
| Use TanStack Query / RTK Query | Use useState / Zustand / Redux |

## Avoiding redundant state
- Don't copy props into state unless you need to "fork" them; sync bugs follow.
- Don't store what you can derive.
- Don't duplicate server data into a store — let the query cache be the source of truth.
- Use functional updates (`setX(prev => ...)`) when next value depends on previous.
