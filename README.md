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

## How to use it

1. Open this folder as a workspace in VS Code.
2. In Copilot Chat, select the **`sdlc-supervisor`** agent (or type `@sdlc-supervisor`).
3. Describe what you want to build, e.g. *"Build a todo REST API."*
4. The supervisor walks the project through
   `GATHERING_REQS → PLANNING → CODING → TESTING`, delegating to each worker and
   keeping [docs/spec.md](docs/spec.md) up to date as the single source of truth.

Or jump straight to a step with a prompt: type `/` in chat and pick
**start-new-feature** or **fix-failing-tests**.

> These files are illustrative scaffolding. Adjust tool sets, models, default
> tech stacks, and test frameworks to fit your real project.
