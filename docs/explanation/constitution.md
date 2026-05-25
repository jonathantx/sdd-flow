---
title: Constitution
---

# Constitution

Rules that every human or AI agent should follow when changing this project.

## Project Identity

Describe the project here:

- product/application name
- target users
- runtime stack
- entrypoints
- important constraints

## Stack

Document the canonical stack here. Include language, framework, package manager,
database, queue, external services, deployment target, and test runner.

## Architecture Rules

- Prefer existing patterns before introducing new abstractions.
- Do not add dependencies without a clear reason.
- Keep changes scoped to the active SPEC/task.
- Treat shared resources as sequential work.
- Update documentation when behavior changes.

## Security Rules

- Do not commit secrets.
- Do not remove validation to make a test pass.
- Do not skip/delete tests unless the SPEC explicitly approves it.
- Document security-sensitive decisions in an ADR.

## SDD Rules

- `docs/changes` is the source of truth for active work.
- A feature uses PRD, SPEC, tasks, implementation, archive.
- A fix can use the direct `/fix` flow.
- A chore can be a direct commit unless it needs durable documentation.
- Architecture decisions go in `docs/adr`.

