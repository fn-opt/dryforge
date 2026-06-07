# dryforge

**An all-in-one harness that keeps every step honest — from project design to code execution.**

> Your agent works like a senior developer.

dryforge leads your agent. Express your intent once — that's exactly what gets built. Senior-level execution, zero drift.

**Install:**

Claude Code:
```
/plugin marketplace add fn-opt/dryforge
/plugin install dryforge
```

Codex:
```
codex plugin marketplace add fn-opt/dryforge
codex plugin add dryforge@dryforge
```

---

**Building with AI got easy. Managing didn't.**

- The code gets written, but it drifts from what you actually wanted.
- Specs miss requirements. Plans are full of implementation code that doesn't match reality.
- Knowledge evaporates between sessions — every new conversation starts from zero.
- You end up babysitting: re-explaining context, catching drift, redoing work.

The agent can build. What's missing is the system that keeps the build honest.

---

## What dryforge does

**A project harness that accumulates knowledge.** Architecture, domain rules, security boundaries, decisions and their rationale — captured once, carried forward. Every new session starts with full project context. The harness grows with your project and works without dryforge — any agent reads it and stays grounded.

```
your-project/
├── CLAUDE.md                  # entry point for Claude Code — project identity + work rules
├── AGENTS.md                  # entry point for Codex — identical content
├── docs/
│   ├── architecture.md        # system composition: components, flow, dependencies
│   ├── business-rules.md      # domain logic: entities, invariants, edge cases
│   ├── security.md            # security policy: protected assets, access, audit
│   ├── standards.md           # the rules: hard gates, conventions, boundaries
│   ├── engineering-notes.md   # hard-won knowledge: traps, mechanisms, checklists
│   ├── operations.md          # how to run it: setup, build, deploy
│   ├── contracts.md           # external interface contracts
│   └── tracking/
│       ├── status.md          # where the project stands vs. its full scope
│       ├── decisions/         # decision records (ADRs) — what was chosen, and why
│       └── findings.md        # known unresolved problems
└── <module>/AGENTS.md         # per-module scope, boundaries, invariants
```

**Structured documents, validated against real code.** Spec and plan have strict roles — no missing requirements, no misalignment. Before execution, every document is checked against your actual codebase. Wrong paths, broken structures — caught and fixed. Other tools execute documents as-is. dryforge validates first.

**Zero-waste execution.** The plan isn't written and then figured out at runtime — it's structured for optimal execution from the start. Dependencies, parallelism, risk levels, verification strategy — all computed at design time. dryforge then executes exactly that: up to 8 concurrent tasks, adaptive verification per risk, zero unnecessary overhead. The execution is precise because the plan was built to be precise.

---

## Entry points

### Start from an idea.

```
/dryforge:ready → /dryforge:go
```

Describe what you want. `ready` runs a senior-level brainstorming session — draws out your intent completely, asks until nothing is ambiguous. If you don't specify a tech stack, it recommends one. It designs to your project's scale — no over-engineering, no under-engineering. The result is a complete, execution-ready design. Then `go` builds it.

### Already have documents? Use them.

```
/dryforge:set → /dryforge:go
```

You don't need `ready` to produce your documents. Bring whatever you have — from any tool, any session, or your own writing. `set` reads them, identifies gaps, asks what's unclear, and shapes them into something complete and executable. Then `go` runs it.

### Not built with dryforge? Bring it.

```
/dryforge:migration
```

Your project wasn't built with dryforge? Doesn't matter. `migration` reads your codebase, generates the harness automatically, and asks when information is missing. The result is a project that's stronger than before — because even intent you never wrote down gets surfaced and captured.

---

## Commands

| Command | What it does |
|---|---|
| `/dryforge:ready` | Brainstorm → complete design, scaled to your project |
| `/dryforge:set` | Validate any existing documents, fill gaps, make them executable |
| `/dryforge:go` | Zero-waste parallel execution from the designed plan |
| `/dryforge:migration` | Onboard an existing project into dryforge |

## Requirements

- git
- Claude Code or Codex

## License

MIT
