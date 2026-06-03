# dryforge

*[한국어](./README_KO.md)*

> Ready or Set, and Go!
> Miswritten docs or a rough idea — two commands, and it's built.

**Install:**

```
codex plugin marketplace add fn-opt/dryforge
codex plugin add dryforge@dryforge
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

## What makes dryforge different: set

When you start a task, you rarely have zero documentation. There's almost always something — a spec you wrote, a plan from another tool, documents an agent produced in a previous session.

The problem is that no one checks whether those documents are actually correct. Wrong paths, missing requirements, structures that don't match the code — catch them before execution and it's a fix; catch them after and it's a rework.

Other plugins execute your documents as-is. `set` dissects them against your actual codebase — finds the parts that went wrong without you noticing, corrects them, and revives the documents to match your intent, preventing the work from drifting off course.

Less rework. Higher quality output.

---

## 2x faster than typical harnesses — without cutting corners

Most harnesses burn time on ceremony: a worktree per task, dependency reinstall per worktree, full verification per wave, verbose progress narration. dryforge eliminates all of it.

- **Adaptive isolation.** Sequential tasks commit directly — no worktree, no reinstall, no gate. Worktrees spin up only when parallel tasks actually need file isolation. Single-task wave overhead is zero.
- **Adaptive dispatch.** Tiny low-risk tasks can run inline; subagents are reserved for real parallelism, context isolation, or independent review.
- **Active dependency optimization.** The orchestrator analyzes what each task actually needs. Infrastructure booting? Tasks that don't need it start immediately. Dependencies installing? Scaffold continues in parallel. Idle time approaches zero.
- **Dependency graph computed upfront.** Which tasks wait on which, whether codegen or schema generation needs to re-run mid-flight — the producer calculates all of it. `go` just follows the graph.
- **Adaptive review.** After all waves merge, a single reviewer checks the full diff for spec conformance and code quality in one pass. High-risk tasks get mid-run checks to catch drift early.
- **Efficient output.** No narrating every internal step. You see key notifications and the final result. Output tokens are usage — dryforge spends them efficiently.

---

## Whatever your starting point, the result is the same

### Path 1 — You already have documents

```
$set    →    $go
```

`set` doesn't take your documents and run. It reads your actual codebase and validates first:

- Catches wrong paths, nonexistent files, and broken structures.
- Traces spec↔plan both ways — finds missing requirements and groundless tasks.
- Strips out implementation code that crept in, leaving only functional goals.
- Asks about ambiguities instead of guessing.
- Computes task dependencies and determines parallel execution order.

### Path 2 — Start from an idea

```
$ready    →    $go
```

`ready` draws out your intent through conversation. Not a checklist — a real dialogue. It digs deep into functional intent, converges fast on technical choices by leading with recommendations. What it can derive from the code, it handles on its own. It only asks what only you can decide.

It reads the code, writes documents grounded in your project's context, and self-validates that no decisions are missing.

### `go` — Execution

- **Parallel execution by dependency graph.** What can run together, runs together. Up to 8 concurrent tasks.
- **Adaptive isolation.** Worktrees only when parallel tasks need physical file separation. Sequential tasks commit directly — zero overhead.
- **Adaptive dispatch.** Low-risk micro-tasks avoid subagent overhead while keeping commits and verification evidence.
- **Right-sized verification.** One final review by default. Mid-run checks only for high-risk tasks with downstream dependents.
- **Asks when stuck.** Escalates to you instead of guessing.
- **Main protection.** Main stays untouched until you approve. Greenfield projects work directly on main — no ceremony for an empty repo.

---

## Commands

| Command | What it does |
|---|---|
| `$ready <goal>` | Understands intent through dialogue → writes docs grounded in your codebase |
| `$set <spec> <plan>` | Validates, fixes, and completes existing docs against real code |
| `$go` | Parallel execution, right-sized verification, asks when stuck |

## Updates

```
codex plugin marketplace upgrade dryforge
```

## Requirements

- **git** — uses git for branch isolation and parallel worktrees. No repo? It offers `git init`.
- **Codex** — install through a Codex plugin marketplace or a shared Codex plugin link.

## License

MIT
