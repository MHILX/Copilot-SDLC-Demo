# Building an End-to-End SDLC Experience with GitHub Copilot Customization

A design and planning document for orchestrating requirement gathering, planning, coding, testing, and bug-fixing through a multi-agent setup built entirely on **GitHub Copilot's native customization features** (custom agents, subagents, instructions, and prompt files).

> **Status:** Design only. No implementation has been started.
> **Chosen approach:** Copilot customization (in-editor, no backend service).
> **Last updated:** 2026-06-26

---

## 1. Goal

Create a Copilot-driven experience that walks a project through the full software development lifecycle (SDLC):

1. **Gather requirements** (clarify scope, ask questions)
2. **Plan** (architecture, file structure, tech stack)
3. **Write code** (implement files)
4. **Test** (unit tests, edge cases)
5. **Fix bugs** (cyclic feedback loop: code → test → fail → fix)

---

## 2. Architecture Decision: Multi-Agent Behind a Single Interface

Use a **multi-agent orchestration flow** wrapped behind a **single user-facing entry point** (a *Supervisor / Router* pattern).

### Why multi-agent instead of one mega-prompt

A single LLM prompt trying to gather requirements, write full-stack code, run tests, and debug will hit:

- **Context-window exhaustion**
- **Hallucination**
- **Task drift**

Splitting the problem into specialized roles produces better, more focused results.

### The specialized roles

| Agent | Responsibility |
|-------|----------------|
| **Product Manager (PM)** | Requirement gathering, scope definition, clarifying questions |
| **Architect** | Turns finalized requirements into file structure, implementation map, and tech-stack decisions |
| **Developer** | Writes/edits files, produces clean code |
| **Reviewer** | Reviews the Developer's code for quality, security, and standards adherence before testing |
| **QA / Tester** | Writes unit tests, reviews edge cases, runs tests, reports failures |

### Supervisor / Worker pattern

The user interacts only with the **Supervisor**. The Supervisor tracks overall project **state** and routes the task to the right worker:

```
State: GATHERING_REQS  →  PLANNING  →  CODING  →  REVIEW  →  TESTING  →  (loop back as needed)
```

```
[User Input]
     │
     ▼
┌──────────────┐      No      ┌─────────────────────────┐
│ Reqs Clear?  ├─────────────►│ PM Agent:               │
└──────┬───────┘              │ Ask clarifying question │
       │ Yes                  └─────────────────────────┘
       ▼
┌──────────────────────┐
│ Architect Agent:     │
│ Create Spec & Files  │
└──────┬───────────────┘
       ▼
┌──────────────────────┐
│ Developer Agent:     │
│ Implement Code Blocks│
└──────┬───────────────┘
       ▼
┌──────────────────────┐│ Reviewer Agent:      │
│ Review Code Quality  │
└──────┬──────────────┘
       │ Changes requested
       ▼
   (back to Developer Agent for a patch)
       │ Approved
       ▼
┌──────────────────────┐│ QA Agent:            │
│ Write & Run Tests    │
└──────┬───────────────┘
       │ Fail
       ▼
   (back to Developer Agent for a patch)
```

---

## 3. Why Copilot Customization (and Not a Custom Extension)

The SDLC loop needs to **edit files** and **run tests** directly in the workspace. That capability lives in the **in-editor surface**, not in a webhook-based GitHub Copilot Extension.

A custom GitHub Copilot Extension (GitHub App + webhook backend) would:

- Respond **into chat over SSE** only.
- **Not** get free local file-editing or "click to accept creating `server.js`" on disk.
- Require backend infrastructure (web service, state store, auth) to operate and secure.

By contrast, **Copilot customization** runs inside VS Code's agent mode and provides **native file-edit and test-execution access** with **no backend to build or maintain**. This is why it is the chosen approach.

---

## 4. Implementation Approach: Copilot Customization

This maps the multi-agent design onto Copilot's **native** features — no web service, no Redis, no webhooks.

| Design concept | Implementation |
|----------------|----------------|
| **Supervisor** | A custom agent (`.agent.md`) that owns the state machine (`GATHERING_REQS → PLANNING → CODING → REVIEW → TESTING`) and delegates |
| **PM worker** | Subagent for requirements / clarifying questions |
| **Architect worker** | Subagent for file structure + tech-stack spec |
| **Developer worker** | Subagent that writes/edits files |
| **Reviewer worker** | Subagent that reviews code for quality, security, and standards before testing |
| **QA worker** | Subagent that writes tests, runs them, reports failures |
| **Shared rules** | `AGENTS.md` / `.instructions.md` with conventions all agents obey |
| **State** | Lives in the conversation + a tracked spec/todo file (no database needed) |
| **Repeatable kickoffs** | Prompt files (`.prompt.md`) such as "start new feature" |
| **Test/fix loop** | QA agent runs the suite in the integrated terminal, feeds failures back to the Developer agent |
| **Full autonomy (optional)** | Push to GitHub and hand off to the Copilot coding agent for PR-based fixes |

### Why this approach

- Lowest effort to a working SDLC loop.
- Native workspace edit + terminal/test execution.
- No backend infrastructure to operate or secure.
- All artifacts are version-controlled markdown that lives with the repo.

---

## 5. Proposed File Layout

All customization lives in the workspace and is committed alongside the code:

```
.github/
  copilot-instructions.md        # Repo-wide conventions all agents obey
AGENTS.md                        # Shared rules / project context (optional companion)
.github/
  agents/
    sdlc-supervisor.agent.md     # Supervisor: owns state machine + delegation
    pm.agent.md                  # PM worker: requirements & clarifying questions
    architect.agent.md           # Architect worker: spec + file structure + stack
    developer.agent.md           # Developer worker: writes/edits files
    reviewer.agent.md            # Reviewer worker: reviews code quality & security
    qa.agent.md                  # QA worker: writes & runs tests, reports failures
  instructions/
    coding-standards.instructions.md   # applyTo code files
    testing-standards.instructions.md  # applyTo test files
  prompts/
    start-new-feature.prompt.md  # Repeatable kickoff
    fix-failing-tests.prompt.md  # Repeatable test/fix kickoff
```

> Exact folder conventions (e.g., `.github/agents` vs. workspace-level) will be confirmed at implementation time against the current VS Code Copilot customization docs.

---

## 6. Components to Build

### 6.1 Supervisor agent
- Owns the state machine: `GATHERING_REQS → PLANNING → CODING → REVIEW → TESTING`.
- Decides which worker to delegate to based on current state and user input.
- Maintains a tracked spec/todo file as the source of truth for project state.

### 6.2 PM agent
- Gathers and clarifies requirements.
- Asks targeted questions until scope is clear; writes finalized requirements to the spec file.

### 6.3 Architect agent
- Converts finalized requirements into a file structure, implementation map, and tech-stack decisions.
- Produces the plan the Developer agent will follow.

### 6.4 Developer agent
- Implements/edits files according to the Architect's plan.
- Produces clean, idiomatic code; makes only the changes required.

### 6.5 Reviewer agent
- Reviews the Developer's code against the coding standards and security (OWASP Top 10) concerns.
- Checks spec fidelity and maintainability; approves or routes specific change requests back to the Developer via the Supervisor.

### 6.6 QA agent
- Writes unit tests and covers edge cases.
- Runs the test suite in the integrated terminal.
- Reports failures back so the Supervisor can route to the Developer agent for a patch.

### 6.7 Shared rules & prompts
- `copilot-instructions.md` / `AGENTS.md`: conventions every agent obeys.
- `.instructions.md` files scoped via `applyTo` for coding vs. testing standards.
- `.prompt.md` files for repeatable kickoffs (new feature, fix failing tests).

---

## 7. Test / Fix Loop

1. **QA agent** runs the test suite in the integrated terminal.
2. On failure, it captures the error output and reports it to the **Supervisor**.
3. The Supervisor routes the failure to the **Developer agent** to issue a patch.
4. Loop repeats (`CODING → TESTING`) until tests pass.
5. **Optional full autonomy:** push to GitHub and assign the issue to the **Copilot coding agent**, which opens a PR, lets CI run, and iterates on fixes.

---

## 8. Resources

- **VS Code Copilot customization:** custom agents (`.agent.md`), subagents, instructions (`.instructions.md`), prompt files (`.prompt.md`), and `AGENTS.md` / `copilot-instructions.md`.
- **GitHub Copilot coding agent:** for optional autonomous test-and-fix-via-PR once the repo is on GitHub.

---

## 9. Open Decisions (To Confirm Before Implementation)

- [ ] Target tech stacks the Architect/Developer agents should default to.
- [ ] Test framework(s) the QA agent should standardize on.
- [ ] Where the tracked spec/state file should live (e.g., `docs/spec.md`).
- [ ] Whether to wire in the GitHub Copilot coding agent for autonomous PR fixes.
- [ ] Confirm current folder conventions for agents/instructions/prompts against the docs.
