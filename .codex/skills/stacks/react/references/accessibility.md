# React Accessibility (a11y)

Accessible UI works for keyboard, screen reader, and low-vision users. Build it in from the start — retrofitting is expensive.

## Semantic HTML first
The element is the API. Native elements carry roles, focus, and keyboard behavior for free. Reach for ARIA only when no native element fits.

```tsx
// Good: a real button (focusable, Enter/Space, role="button")
<button onClick={save}>Save</button>

// Bad: a div pretending to be a button (no focus, no keyboard)
<div onClick={save}>Save</div>
```

Use `<nav>`, `<main>`, `<header>`, `<ul>/<li>`, `<button>`, `<a href>` for their meaning. A link navigates; a button performs an action.

## ARIA only when needed
First rule of ARIA: don't use ARIA if a native element does the job. When you must (custom widgets), follow the WAI-ARIA Authoring Practices.

```tsx
<button aria-expanded={open} aria-controls="menu" onClick={() => setOpen(!open)}>
  Menu
</button>
<ul id="menu" hidden={!open} role="menu">…</ul>
```

Don't set `role` that contradicts the element, and don't add `aria-*` that lies about state.

## Labels
Every interactive control needs an accessible name.

```tsx
// Visible label tied by htmlFor/id
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// Icon-only button needs aria-label
<button aria-label="Close dialog" onClick={close}>
  <XIcon aria-hidden="true" />
</button>
```

Decorative icons get `aria-hidden="true"`; meaningful images get `alt`.

## Focus and keyboard
- All actions must be reachable and operable by keyboard (Tab, Enter, Space, Esc, arrows for widgets).
- Manage focus on route change, modal open/close. Move focus into a dialog and restore it on close.
- Never remove focus outlines without providing a visible alternative.

```tsx
function Dialog({ onClose, children }: DialogProps) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => { ref.current?.focus(); }, []);
  return (
    <div
      ref={ref}
      role="dialog"
      aria-modal="true"
      tabIndex={-1}
      onKeyDown={(e) => e.key === "Escape" && onClose()}
    >
      {children}
    </div>
  );
}
```

## Color and contrast
- Text contrast must meet WCAG AA: 4.5:1 for normal text, 3:1 for large text.
- Never use color as the only signal (e.g. error state needs text/icon, not just red).

## Accessible forms
- Associate every input with a label.
- Tie errors to the field with `aria-describedby` and mark invalid fields with `aria-invalid`.
- Group related controls with `<fieldset>`/`<legend>`.

```tsx
<label htmlFor="pwd">Password</label>
<input
  id="pwd"
  type="password"
  aria-invalid={!!error}
  aria-describedby={error ? "pwd-err" : undefined}
/>
{error && <p id="pwd-err" role="alert">{error}</p>}
```

Use `role="alert"` (or an `aria-live` region) so screen readers announce dynamic errors.

## Live regions
Announce async updates (toasts, loading results) without stealing focus.

```tsx
<div aria-live="polite" className="sr-only">{statusMessage}</div>
```

## Testing a11y
- Lint with `eslint-plugin-jsx-a11y`.
- Automated checks with `axe-core` / `jest-axe` or `@axe-core/playwright`.
- Query by role in tests (see `testing.md`) — if `getByRole` can't find your control, neither can a screen reader.

```tsx
import { axe } from "jest-axe";

test("has no a11y violations", async () => {
  const { container } = render(<SignupForm />);
  expect(await axe(container)).toHaveNoViolations();
});
```

Automated tools catch ~30–40%. Also test manually: tab through the page and use a screen reader.
