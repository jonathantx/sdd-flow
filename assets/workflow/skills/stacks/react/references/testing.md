# React Testing

Test what users experience, not internal wiring. Stack: React Testing Library (RTL) + Vitest or Jest, `@testing-library/user-event`, and MSW for network.

## Guiding principle
"The more your tests resemble the way your software is used, the more confidence they give." Test behavior through the rendered output, not state variables or function calls.

```tsx
// Bad: asserting implementation detail
expect(wrapper.state("count")).toBe(1);

// Good: assert what the user sees
expect(screen.getByText("Count: 1")).toBeInTheDocument();
```

## Setup (Vitest example)
```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";
export default defineConfig({
  test: { environment: "jsdom", globals: true, setupFiles: ["./test/setup.ts"] },
});

// test/setup.ts
import "@testing-library/jest-dom/vitest";
```

## Query by role (priority order)
Prefer accessible queries; they double as a11y checks.
1. `getByRole` (with `name`) — buttons, links, headings, inputs.
2. `getByLabelText` — form fields.
3. `getByPlaceholderText`, `getByText`.
4. `getByTestId` — last resort.

```tsx
import { render, screen } from "@testing-library/react";

test("renders a submit button", () => {
  render(<Form />);
  expect(screen.getByRole("button", { name: /submit/i })).toBeEnabled();
});
```

## user-event over fireEvent
`user-event` simulates real interactions (focus, key sequences). Always `await` it.

```tsx
import userEvent from "@testing-library/user-event";

test("submits the typed name", async () => {
  const user = userEvent.setup();
  const onSubmit = vi.fn();
  render(<NameForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText(/name/i), "Ada");
  await user.click(screen.getByRole("button", { name: /save/i }));

  expect(onSubmit).toHaveBeenCalledWith({ name: "Ada" });
});
```

## Async UI: findBy + waitFor
Use `findBy*` (returns a promise) for elements that appear after async work.

```tsx
test("shows users after fetch", async () => {
  render(<UserList />);
  expect(await screen.findByText("Ada Lovelace")).toBeInTheDocument();
});
```

Avoid arbitrary `setTimeout`; let queries wait.

## Mocking the network with MSW
Prefer Mock Service Worker over mocking `fetch` directly — it intercepts at the network layer, so code under test stays untouched.

```ts
// test/server.ts
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";

export const server = setupServer(
  http.get("/api/users", () =>
    HttpResponse.json([{ id: "1", name: "Ada Lovelace" }])
  )
);

// test/setup.ts
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Override per test for error paths:

```tsx
test("shows error on 500", async () => {
  server.use(http.get("/api/users", () => new HttpResponse(null, { status: 500 })));
  render(<UserList />);
  expect(await screen.findByRole("alert")).toHaveTextContent(/failed/i);
});
```

## Testing hooks
Use `renderHook` for hooks with no UID, and `act` for updates.

```tsx
import { renderHook, act } from "@testing-library/react";

test("useCounter increments", () => {
  const { result } = renderHook(() => useCounter());
  act(() => result.current.inc());
  expect(result.current.count).toBe(1);
});
```

## Providers in tests
Wrap with the same providers the app uses (Query client, router, theme). Create a custom `render`.

```tsx
function renderWithProviders(ui: React.ReactElement) {
  const qc = new QueryClient();
  return render(<QueryClientProvider client={qc}>{ui}</QueryClientProvider>);
}
```

## What to test
- User-visible behavior, edge/empty/error states, accessibility (role queries).
- Skip: exact class names, internal state, third-party lib internals.
- Aim for confidence per test, not raw coverage numbers.
