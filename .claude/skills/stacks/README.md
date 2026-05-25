# Stack Skills

Each subfolder here is a **knowledge base** for one technology stack. A stack
skill is what stops the AI agent from hallucinating: before writing code, the
implementation commands (`/spec`, `/tasks`, `/implement`) load the skill that
matches the project's stack (as recorded by `/analyze` in the constitution).

## Layout of a stack skill

```
<stack>/
├── SKILL.md              # frontmatter (name, version, description) + "when used" + golden rules + index
└── references/
    ├── architecture.md   # project layout, layering, dependency direction
    ├── api.md            # HTTP API / public surface design (backend) — N/A for pure UI
    ├── components.md     # component design (frontend)
    ├── state.md          # state management (frontend)
    ├── persistence.md    # data access, migrations, transactions (backend)
    ├── performance.md    # rendering/perf (frontend)
    ├── accessibility.md  # a11y (frontend)
    ├── testing.md        # test strategy and examples
    ├── security.md       # validation, authz, secrets, OWASP
    ├── observability.md  # logging, metrics, tracing (backend)
    └── conventions.md    # code style, naming, lint/format, anti-patterns
```

Not every stack has every file — backend stacks have `api/persistence/observability`,
frontend stacks have `components/state/performance/accessibility`. All have
`architecture/testing/security/conventions`.

## Available stacks

- `node-typescript` — Node.js + TypeScript backend (Express/Fastify/Nest)
- `php-laravel` — PHP 8.2+ / Laravel 11+
- `react` — React 18/19 + TypeScript
- `svelte` — Svelte 5 (runes) + SvelteKit + TypeScript

## Adding a new stack

Copy the layout of the closest existing stack, keep the same file names, and
register its anchor in `analyze-project/scripts/detect-stack.sh`.
