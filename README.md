# Copilot SDLC Demo

A reference workspace showing how to build an **end-to-end SDLC experience** using only GitHub Copilot's native customization features — no backend service, no webhooks.

It implements the **Supervisor / Worker** multi-agent pattern described in
[Copilot-SDLC-Agent-Design.md](../Copilot-SDLC-Agent-Design.md):

```
@sdlc-supervisor  (entry point, owns the state machine)
   ├── pm          → gather & clarify requirements
   ├── architect   → spec, file structure, tech stack
   ├── developer   → write / edit code
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
| Plan | **Architect** | Tech stack, file structure, implementation plan |
| Code | **Developer** | Checks off plan items as files land in `src/` |
| Test & Fix | **QA** | Test command and results; failures loop back to Developer |

The **Supervisor** owns the `GATHERING_REQS → PLANNING → CODING → TESTING` state
machine and routes work to the right agent. For the full rationale (why split the
work, and why Copilot customization over a backend), see
[Copilot-SDLC-Agent-Design.md](Copilot-SDLC-Agent-Design.md).

## What's in here (all files are examples)

```
Copilot-SDLC-Demo/
├─ README.md                        ← this file
├─ .github/
│  ├─ copilot-instructions.md       ← shared rules every agent obeys
│  ├─ agents/
│  │  ├─ sdlc-supervisor.agent.md   ← Supervisor: state machine + delegation
│  │  ├─ pm.agent.md                ← PM worker (subagent)
│  │  ├─ architect.agent.md         ← Architect worker (subagent)
│  │  ├─ developer.agent.md         ← Developer worker (subagent)
│  │  └─ qa.agent.md                ← QA worker (subagent)
│  ├─ instructions/
│  │  ├─ coding-standards.instructions.md     ← applyTo source files
│  │  └─ testing-standards.instructions.md    ← applyTo test files
│  └─ prompts/
│     ├─ start-new-feature.prompt.md
│     └─ fix-failing-tests.prompt.md
├─ docs/
│  └─ spec.md                       ← tracked project state / source of truth
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
   `GATHERING_REQS → PLANNING → CODING → TESTING`, delegating to each worker and
   keeping [docs/spec.md](docs/spec.md) up to date as the single source of truth.

Or jump straight to a step with a prompt: type `/` in chat and pick
**start-new-feature** or **fix-failing-tests**.

## Use it in your own project

To follow this SDLC process in a new or existing repo, copy the customization
files into it:

1. Copy these into the root of your repo, preserving paths:
   - `.github/copilot-instructions.md`
   - `.github/agents/` (all five `.agent.md` files)
   - `.github/instructions/` (both `.instructions.md` files)
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
- **Test framework & commands:** edit
  [.github/instructions/testing-standards.instructions.md](.github/instructions/testing-standards.instructions.md).
- **Default tech stack:** note your preferences in
  [.github/copilot-instructions.md](.github/copilot-instructions.md) so every agent obeys them.

### Starting a new feature

[docs/spec.md](docs/spec.md) is the tracked source of truth. For a fresh feature,
reset its **Current State** to `GATHERING_REQS` and clear the Goal, Requirements,
Plan, and Test Results sections — the supervisor refills them as it works.

### Optional: full autonomy via GitHub

Once the repo is on GitHub, you can hand the test/fix loop to the **Copilot coding
agent** to iterate on fixes via pull requests and CI, instead of running the loop
locally.

> These files are illustrative scaffolding. Adjust tool sets, models, default
> tech stacks, and test frameworks to fit your real project.
