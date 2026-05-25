---
name: analyze-project
version: 1.0.0
description: Detecta as stacks de frontend e backend de um repositório (existente ou novo), registra no constitution.md e ativa as skills de stack corretas. Use no início, antes de começar qualquer change, ou quando a stack do projeto mudar.
---

# Analyze Project

**When this is used (junior-friendly):** Run this once when you start using the
workflow in a project. It looks at your code, figures out which technologies you
use (Node, PHP/Laravel, React, Svelte…), and turns on the right "knowledge packs"
(stack skills) so the assistant writes code the right way for *your* stack.

## What it produces

- An updated `docs/explanation/constitution.md` with the detected/selected stack.
- A list of **active stacks** mapped to skills under `skills/stacks/<name>/`.

## How it decides (anchor files)

| Anchor | Stack | Skill |
|---|---|---|
| `package.json` + `express`/`fastify`/`nestjs` + `typescript` | Node/TS backend | `node-typescript` |
| `package.json` + `react`/`next` | React frontend | `react` |
| `svelte.config.js` / `@sveltejs/kit` / `*.svelte` | Svelte | `svelte` |
| `composer.json` + `laravel/framework` | PHP/Laravel | `php-laravel` |

Run the helper `scripts/detect-stack.sh <project-root>` to get a machine-readable
report; then confirm with the user before writing the constitution.

## Procedure

1. Run `scripts/detect-stack.sh` (or inspect anchors manually if absent).
2. If no application code exists → bootstrap mode: ask the user which stacks to use.
3. Confirm findings with the user (one question at a time).
4. Update `constitution.md` Project Identity + Stack + add an `## Active Stacks` section.
5. Tell the user to run `sdd sync` to propagate, and `sdd doctor` to validate.

## Golden rules

- Detect before asking. Never invent a stack without evidence.
- The matching stack skill is the **canonical knowledge base** — implementation
  steps MUST load it before writing code, so the agent never hallucinates APIs.
- Keep human-written architecture/security rules in the constitution intact.
