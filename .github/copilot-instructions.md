# Project Guidelines

These rules apply to every agent in this workspace (Supervisor, PM, Architect, Developer, Reviewer, QA).

## Workflow

- The project moves through a state machine: `GATHERING_REQS → [DESIGN] → PLANNING → CODING → REVIEW → TESTING → [DEPLOYMENT_READINESS] → DONE`. The `DESIGN` phase is optional (frontend/UI projects only). `DEPLOYMENT_READINESS` is an optional pre-merge gate.
- [docs/spec.md](../docs/spec.md) is the single source of truth for requirements, plan, and current state. Keep it updated as work progresses.
- Do not skip ahead: code is only written after requirements are clear and a plan exists.
- The **Developer must verify the project builds cleanly** before handing off to REVIEW.
- The **Reviewer performs a scope audit** (per `.github/instructions/scope-audit.instructions.md`) to catch cross-domain contamination.

## Code Style

- Prefer small, focused files and functions with clear names.
- Make only the changes required for the current task; avoid unrelated refactors.
- No commented-out code, placeholder TODOs, or unused imports left behind.
- Never hardcode secrets, keys, or tokens — use environment variables or a secrets manager.

## Architecture

- Application code lives in `src/`. Tests live in `tests/`.
- Keep business logic separate from I/O (HTTP handlers, DB access, file system).

## Build and Test

- Tests must pass before a feature is considered done.
- The QA agent runs the test suite in the integrated terminal and reports failures verbatim.
- The Developer must verify a clean build (zero errors) before the REVIEW phase.

## Conventions

- Every change should be traceable to a requirement in [docs/spec.md](../docs/spec.md).
- When requirements are ambiguous, ask the user rather than guessing.

## Instruction Files

Phase-specific standards are in `.github/instructions/`:
- `coding-standards.instructions.md` — code quality rules for `src/`.
- `frontend-ux.instructions.md` — UX and accessibility rules for UI files.
- `testing-standards.instructions.md` — test quality rules for `tests/`.
- `scope-audit.instructions.md` — blast-radius checking (declare → implement → verify).
- `deployment-readiness.instructions.md` — pre-deployment security and build checklist.
