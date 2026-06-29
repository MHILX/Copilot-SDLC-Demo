# Copilot SDLC Demo

A reference workspace showing how to build an **end-to-end SDLC experience** using only GitHub Copilot's native customization features — no backend service, no webhooks.

It implements the **Supervisor / Worker** multi-agent pattern described in
[Copilot-SDLC-Agent-Design.md](Copilot-SDLC-Agent-Design.md):

```
@sdlc-supervisor  (entry point, owns the state machine)
   ├── pm          → gather & clarify requirements
   ├── designer    → user flows, states & accessibility (frontend only)
   ├── architect   → spec, file structure, tech stack
   ├── developer   → write / edit code
   ├── reviewer    → review code for quality & security
   └── qa          → write & run tests, report failures
```

## How the SDLC maps to AI agents

The classic software development lifecycle is run by a team of specialized AI
agents instead of one general-purpose prompt. Each agent owns one phase, does its
work, and records the result in [docs/spec.md](docs/spec.md) so the next agent has
a shared, version-controlled source of truth. A human stays in the loop —
reviewing and accepting file edits and test runs — so this assists your SDLC
rather than running unattended.

| SDLC phase | Agent | Writes to `docs/spec.md` |
|------------|-------|--------------------------|
| Requirements | **PM** | Goal, requirements, acceptance criteria, out-of-scope |
| Design (frontend only) | **Designer** | Screens & flows, states, design tokens, accessibility |
| Plan | **Architect** | Tech stack, file structure, implementation plan |
| Code | **Developer** | Checks off plan items as files land in `src/`; verifies build |
| Review | **Reviewer** | Review verdict, scope audit, and findings; changes loop back to Developer |
| Test & Fix | **QA** | Test command and results; failures loop back to Developer |
| Deployment Readiness _(optional)_ | **Reviewer** | Pre-deploy checklist: build, tests, secrets, config, deps, cleanup |

The **Supervisor** owns the `GATHERING_REQS → [DESIGN] → PLANNING → CODING → REVIEW → TESTING → [DEPLOYMENT_READINESS] → DONE` state
machine and routes work to the right agent. The optional `DESIGN` phase runs only
for frontend or UI-heavy projects. `DEPLOYMENT_READINESS` is an optional pre-merge
gate that validates build, security, and configuration before marking the feature done. For the full rationale (why split the
work, and why Copilot customization over a backend), see
[Copilot-SDLC-Agent-Design.md](Copilot-SDLC-Agent-Design.md).

## What's in here (all files are examples)

```
Copilot-SDLC-Demo/
├─ README.md                        ← this file
├─ LICENSE                          ← MIT license
├─ .gitignore
├─ .github/
│  ├─ copilot-instructions.md       ← shared rules every agent obeys
│  ├─ agents/
│  │  ├─ sdlc-supervisor.agent.md   ← Supervisor: state machine + delegation
│  │  ├─ pm.agent.md                ← PM worker (subagent)
│  │  ├─ designer.agent.md          ← Designer worker (subagent, frontend only)
│  │  ├─ architect.agent.md         ← Architect worker (subagent)
│  │  ├─ developer.agent.md         ← Developer worker (subagent)
│  │  ├─ reviewer.agent.md          ← Reviewer worker (subagent)
│  │  └─ qa.agent.md                ← QA worker (subagent)
│  ├─ instructions/
│  │  ├─ coding-standards.instructions.md     ← applyTo source files
│  │  ├─ frontend-ux.instructions.md          ← applyTo UI source files
│  │  ├─ testing-standards.instructions.md    ← applyTo test files
│  │  ├─ scope-audit.instructions.md          ← blast-radius checker
│  │  └─ deployment-readiness.instructions.md ← pre-deploy security & build checklist
│  └─ prompts/
│     ├─ start-new-feature.prompt.md
│     ├─ fix-failing-tests.prompt.md
│     └─ handoff.prompt.md                    ← agent-to-agent orientation prompt
├─ docs/
│  └─ spec.md                       ← tracked project state / source of truth
├─ scripts/
│  ├─ scaffold-sdlc.ps1             ← copy customization into a target repo (PowerShell)
│  └─ scaffold-sdlc.sh              ← copy customization into a target repo (Bash)
├─ src/                             ← (empty) where the Developer agent writes code
│  └─ .gitkeep
└─ tests/                           ← (empty) where the QA agent writes tests
   └─ .gitkeep
```

## Prerequisites

- **VS Code** recent enough to support custom agents (`.agent.md`) and subagents.
- An active **GitHub Copilot** subscription with **agent mode** enabled.
- Custom agents/subagents enabled in settings. If `@sdlc-supervisor` does not
  appear in the chat agent picker, enable custom agents and **reload the window**
  (Command Palette → *Developer: Reload Window*).

## How to use it

1. Open this folder as a workspace in VS Code.
2. In Copilot Chat, select the **`sdlc-supervisor`** agent (or type `@sdlc-supervisor`).
3. Describe what you want to build, e.g. *"Build a todo REST API."*
4. The supervisor walks the project through
   `GATHERING_REQS → PLANNING → CODING → REVIEW → TESTING → [DEPLOYMENT_READINESS] → DONE`,
   delegating to each worker and keeping [docs/spec.md](docs/spec.md) up to date as the
   single source of truth.

Or jump straight to a step with a prompt: type `/` in chat and pick
**start-new-feature** or **fix-failing-tests**.

## Use it in your own project

To follow this SDLC process in a new or existing repo, copy the customization
files into it:

### Quick scaffold (script)

From a clone of this repo, run the script for your shell and point it at a target
folder. It copies the whole `.github` customization and `docs/spec.md`, then
ensures `src/` and `tests/` exist:

```powershell
# Windows / PowerShell
./scripts/scaffold-sdlc.ps1 -Target ../my-project
```

```bash
# macOS / Linux / WSL
./scripts/scaffold-sdlc.sh ../my-project
```

The scripts copy directories wholesale (not a hard-coded file list), so they stay
correct as agents are added or renamed. They prompt before overwriting existing
files — pass `-Force` (PowerShell) or `--force` (Bash) to skip the prompts. Run
them from a clone of this repo, not an empty folder.

### Manual copy

1. Copy these into the root of your repo, preserving paths:
   - `.github/copilot-instructions.md`
   - `.github/agents/` (all seven `.agent.md` files)
   - `.github/instructions/` (all three `.instructions.md` files)
   - `.github/prompts/` (both `.prompt.md` files)
   - `docs/spec.md`
2. Make sure your repo has `src/` and `tests/` folders (add a `.gitkeep` if empty).
3. Reload the VS Code window so the agents are picked up.
4. Select **`sdlc-supervisor`** and describe what you want to build.

### Adapt it to your stack

- **Models & tools:** edit the YAML frontmatter at the top of each
  `.github/agents/*.agent.md` file.
- **Coding conventions:** edit
  [.github/instructions/coding-standards.instructions.md](.github/instructions/coding-standards.instructions.md)
  (its `applyTo` controls which files it governs).
- **Frontend UX & accessibility:** edit
  [.github/instructions/frontend-ux.instructions.md](.github/instructions/frontend-ux.instructions.md)
  to match your design system and accessibility target.
- **Test framework & commands:** edit
  [.github/instructions/testing-standards.instructions.md](.github/instructions/testing-standards.instructions.md).
- **Default tech stack:** note your preferences in
  [.github/copilot-instructions.md](.github/copilot-instructions.md) so every agent obeys them.

### Starting a new feature

[docs/spec.md](docs/spec.md) is the tracked source of truth. For a fresh feature,
reset its **Current State** to `GATHERING_REQS` and clear the Goal, Requirements,
Design, Plan, and Test Results sections — the supervisor refills them as it works.

### Optional: full autonomy via GitHub

Once the repo is on GitHub, you can hand the test/fix loop to the **Copilot coding
agent** to iterate on fixes via pull requests and CI, instead of running the loop
locally.

> These files are illustrative scaffolding. Adjust tool sets, models, default
> tech stacks, and test frameworks to fit your real project.

## Anatomy of an agent file

Each agent lives in `.github/agents/<name>.agent.md`: YAML frontmatter (its
configuration) followed by a Markdown body (its system prompt). Recreating these
from scratch requires getting the frontmatter right, so the fields are:

| Field | Purpose |
|-------|---------|
| `name` | Display name shown in the chat agent picker. |
| `description` | When to use the agent; how the Supervisor (and VS Code) decide to route to it. |
| `tools` | The capabilities the agent may use. Keep this minimal — it is the agent's permission boundary. |
| `model` | Ordered list of acceptable models (first available is used). |
| `user-invocable` | `false` for workers so users don't call them directly — only the Supervisor delegates to them. Omitted on the Supervisor, which is the entry point. |
| `agents` | (Supervisor only) the subagents it is allowed to delegate to. |
| `argument-hint` | (Supervisor only) placeholder text for the user's first message. |

### Tool grants (and why)

Tools are deliberately scoped so each agent can only do its job. This is a key
part of the design — for example, the Reviewer cannot edit code, which keeps
review and implementation separate.

| Agent | `tools` | Why |
|-------|---------|-----|
| `sdlc-supervisor` | `read, search, edit, todo, agent` | Coordinates only: reads/updates `docs/spec.md` (`edit`), tracks phases (`todo`), and delegates (`agent`). No `execute` — it never runs code itself. |
| `pm` | `read, edit, search` | Writes requirements into `docs/spec.md`; no code or test execution. |
| `designer` | `read, edit, search` | Writes the UI/UX design into `docs/spec.md` for frontend projects; no code or test execution. |
| `architect` | `read, edit, search` | Writes the plan into `docs/spec.md`; no code or test execution. |
| `developer` | `read, edit, search, execute` | Writes files under `src/` and may run a command to verify a fix. |
| `reviewer` | `read, search` | Review-only: can read code but **cannot** edit or execute, enforcing the review/implementation split. |
| `qa` | `read, edit, search, execute` | Writes tests under `tests/` and runs the suite in the terminal (`execute`). |

> All workers set `user-invocable: false`; only `sdlc-supervisor` is invoked
> directly. The shared rules in
> [.github/copilot-instructions.md](.github/copilot-instructions.md) apply to every
> agent (an `AGENTS.md` at the repo root is an equivalent alternative this repo
> does not use).

## License

MIT — see [LICENSE](LICENSE). The customization files are examples; reuse and adapt them freely.
