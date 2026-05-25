# React Components

Patterns for writing typed, composable function components.

## Function components with typed props
Type props with a `type` (or `interface`). Avoid `React.FC` — it adds an implicit `children` and weakens generics.

```tsx
type GreetingProps = {
  name: string;
  greeting?: string;
};

function Greeting({ name, greeting = "Hello" }: GreetingProps) {
  return <p>{greeting}, {name}!</p>;
}
```

For components that wrap a DOM element, extend its props:

```tsx
type ButtonProps = React.ComponentPropsWithoutRef<"button"> & {
  variant?: "primary" | "ghost";
};

function Button({ variant = "primary", className, ...rest }: ButtonProps) {
  return <button className={`btn btn-${variant} ${className ?? ""}`} {...rest} />;
}
```

## Children patterns
`children` is the primary composition tool. Type it as `React.ReactNode`.

```tsx
type CardProps = { children: React.ReactNode };
function Card({ children }: CardProps) {
  return <div className="card">{children}</div>;
}
```

Render props / function-as-children for sharing logic with flexible rendering:

```tsx
type ToggleProps = { children: (on: boolean, toggle: () => void) => React.ReactNode };
function Toggle({ children }: ToggleProps) {
  const [on, setOn] = useState(false);
  return <>{children(on, () => setOn((v) => !v))}</>;
}

<Toggle>{(on, toggle) => <button onClick={toggle}>{on ? "On" : "Off"}</button>}</Toggle>;
```

Compound components via attached subcomponents (see `architecture.md` `Card.Header`):

```tsx
Card.Header = function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="card-header">{children}</div>;
};
```

## Composition over prop drilling
If a prop passes through 3+ layers untouched, restructure: pass JSX as a prop/children, or use context for truly global values (theme, current user). Do not reach for context for every shared value — see `state.md`.

```tsx
// Instead of drilling `user` through Layout -> Header -> Avatar,
// compose the slot at the top:
<Layout header={<Header user={user} />}>{page}</Layout>;
```

## Controlled vs uncontrolled
- **Controlled**: value lives in React state; component is the source of truth. Use for validation, dependent fields, instant feedback.
- **Uncontrolled**: the DOM holds the value; read via ref on submit. Use for simple forms and performance.

```tsx
// Controlled
function NameField() {
  const [name, setName] = useState("");
  return <input value={name} onChange={(e) => setName(e.target.value)} />;
}

// Uncontrolled
function NameForm() {
  const ref = useRef<HTMLInputElement>(null);
  const submit = () => console.log(ref.current?.value);
  return (
    <form onSubmit={(e) => { e.preventDefault(); submit(); }}>
      <input defaultValue="" ref={ref} />
    </form>
  );
}
```

Pick one per input. A field that has both `value` and `defaultValue` is a bug.

## Refs
Use `useRef` for mutable values that do not trigger renders and for DOM access. In React 19, `ref` is a regular prop; before 19 use `forwardRef`.

```tsx
// React 19: ref as a prop
function TextInput({ ref, ...props }: React.ComponentPropsWithRef<"input">) {
  return <input ref={ref} {...props} />;
}

// React 18: forwardRef
const TextInput18 = React.forwardRef<HTMLInputElement, React.ComponentPropsWithoutRef<"input">>(
  (props, ref) => <input ref={ref} {...props} />
);
```

Never read/write `ref.current` during render — only in effects or event handlers.

## Keys and lists
Give list items a stable, unique `key` from the data (an id), not the array index, unless the list is static and never reordered. See `performance.md`.

## Anti-patterns to avoid
- Defining a component inside another component's body (remounts every render).
- Spreading unknown props onto DOM elements without typing.
- Mutating props or state objects in place.
