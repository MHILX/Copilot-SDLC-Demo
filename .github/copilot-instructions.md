# Project Guidelines

These rules apply to every agent in this workspace (Supervisor, PM, Architect, Developer, Reviewer, QA).

## Workflow

- The project moves through a state machine: `GATHERING_REQS → [DESIGN] → PLANNING → CODING → REVIEW → TESTING`. The `DESIGN` phase is optional and runs only for frontend or UI-heavy projects.
- [docs/spec.md](../docs/spec.md) is the single source of truth for requirements, plan, and current state. Keep it updated as work progresses.
- Do not skip ahead: code is only written after requirements are clear and a plan exists.

## Code Style

- Prefer small, focused files and functions with clear names.
- Make only the changes required for the current task; avoid unrelated refactors.
- No commented-out code or placeholder TODOs left behind.

## Architecture

- Application code lives in `src/`. Tests live in `tests/`.
- Keep business logic separate from I/O (HTTP handlers, DB access, file system).

## Build and Test

- Tests must pass before a feature is considered done.
- The QA agent runs the test suite in the integrated terminal and reports failures verbatim.

## Conventions

- Every change should be traceable to a requirement in [docs/spec.md](../docs/spec.md).
- When requirements are ambiguous, ask the user rather than guessing.
