# dryforge

*[한국어](./README_KO.md)*

> Ready or Set, and Go!
> Miswritten docs or a rough idea — two commands, and it's built.

**Install:**

```
/plugin marketplace add fn-opt/dryforge
/plugin install dryforge
```

---

## This is why dryforge was made.

> **It stops the agent from going off the rails.**

- Starts coding before figuring out what to build.
- Even with a spec, the work drifts away from intent.
- The plan is full of code that doesn't match reality — the agent ends up fighting its own documents.

> **It fundamentally improves work efficiency.**

- A one-line config change gets a full test suite. A single edit gets triple review.
- Eight independent tasks run one after another, because no one computed which depends on which.

### dryforge fixes both at once

It straightens out document roles, validates them against real code, then builds with right-sized verification and parallel execution.

**`set → go`** — Tears your docs apart and rebuilds them. Fixes what's wrong, fills what's missing, asks about what's unclear.

**`ready → go`** — Asks deeply, writes the docs itself, and executes. End to end.

---

## What makes dryforge different: /set

When you start a task, you rarely have zero documentation. There's almost always something — a spec you wrote, a plan from another tool, documents an agent produced in a previous session.

The problem is that no one checks whether those documents are actually correct. Wrong paths, missing requirements, structures that don't match the code — catch them before execution and it's a fix; catch them after and it's a rework.

Other plugins execute your documents as-is. `set` dissects them against your actual codebase — finds the parts that went wrong without you noticing, corrects them, and revives the documents to match your intent, preventing the work from drifting off course.

Less rework. Higher quality output.

---

## Whatever your starting point, the result is the same

### Path 1 — You already have documents

```
/dryforge:set    →    /dryforge:go
```

`set` doesn't take your documents and run. It reads your actual codebase and validates first:

- Catches wrong paths, nonexistent files, and broken structures.
- Traces spec↔plan both ways — finds missing requirements and groundless tasks.
- Strips out implementation code that crept in, leaving only functional goals.
- Asks about ambiguities instead of guessing.
- Computes task dependencies and determines parallel execution order.

### Path 2 — Start from an idea

```
/dryforge:ready    →    /dryforge:go
```

`ready` draws out your intent through conversation. Not a checklist — a real dialogue. It digs deep into functional intent, converges fast on technical choices by leading with recommendations. What it can derive from the code, it handles on its own. It only asks what only you can decide.

It reads the code, writes documents grounded in your project's context, and self-validates that no decisions are missing.

### `/dryforge:go` — Execution

Run in a fresh session (`/clear`).

- **Parallel execution by dependency graph.** What can run together, runs together. Up to 8 concurrent tasks.
- **Isolated environments.** Each task in its own git worktree. No file collisions.
- **Right-sized verification.** Spec review per task, integration check and code review per batch.
- **Asks when stuck.** Escalates to you instead of guessing.
- **Main protection.** Main stays untouched until you approve.

---

## Commands

| Command | What it does |
|---|---|
| `/dryforge:ready <goal>` | Understands intent through dialogue → writes docs grounded in your codebase |
| `/dryforge:set <spec> <plan>` | Validates, fixes, and completes existing docs against real code |
| `/dryforge:go` | Parallel execution, per-task verification, asks when stuck |

## Updates

```
/plugin
→ Marketplaces → dryforge → Enable auto-update
```

## Requirements

- **git** — uses worktrees for task isolation. No repo? It offers `git init`.
- **Claude Code**

## License

MIT
