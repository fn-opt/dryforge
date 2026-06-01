---
name: go
description: >
  Execute a refined 3-doc (handoff, spec, plan) produced by ready or set:
  wave-based parallel implementation with right-sized verification (test-first where it fits),
  spec-first review, and integration gates, in a fresh session. Use when the user runs /dryforge:go
  after a producer wrote the 3-doc. Requires git.
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, Agent, AskUserQuestion
---

# go

Consume the **3-doc** a producer (ready or set) wrote and realize the spec:
parallel, wave-based execution with right-sized verification (test-first where it fits), spec-first
review, and integration gates. Runs in a fresh session (S2 — clean context, no producer history) — the 3-doc is the only source of truth. **Load `references/orchestration.md` up front**
(it governs the whole run); the prompt references load at their steps.

## Core principles (apply throughout)

- **Follow the plan's Execution Graph; never re-judge dependencies.** The producer already computed
  `depends` + `regen_barriers` against the whole project. Derive waves from it — do not invent,
  drop, or reorder dependencies. (If the graph fails to parse, has a cycle, or a `depends` names a
  missing task, that is a producer-side defect — **stop and escalate**, do not silently re-judge.)
- **Serve the spec.** "Correct" = matches the spec. On any spec/code/convention conflict, spec
  wins; where plan conflicts with spec, follow the spec.
- **escalate-don't-guess.** Architecture mismatch, suspected spec violation, ambiguous task,
  unresolvable conflict → stop and **ask the user**; never guess. When a task returns
  `NEEDS_CONTEXT` / `BLOCKED`, the orchestrator escalates to the user **synchronously** — the run
  pauses until the user responds, never a silent hang or a timeout-drop. The subagents themselves
  never call `AskUserQuestion` (their prompt files carry that fresh-session rule); only the
  orchestrator relays escalations to the user.
- **Protect main; evidence over self-report.** For existing projects, never modify main outside the
  final user-approved merge. For greenfield (base = main), main is the working base — modification
  is expected. Gates pass on captured command exit codes, not on an agent's "looks fine."
- **Floor, not ceiling.** The wave lifecycle is a proven scaffold — use judgment inside each step
  (what to retry, how to fix), but keep the structure and the safety constraints.
- **Report results, not process.** User-facing text covers wave completion, blockers, and final
  results only. Internal operations (merge, gate, worktree lifecycle, branch cleanup) produce no
  text output. Output tokens are direct cost; narrating routine steps is waste.

## Input & preconditions

- Invocation: `/dryforge:go`. Load the 3-doc (handoff → spec → plan) from the project's
  `.dryforge/` (project-root-relative). If absent, ask for the path.
- **git required** — worktree isolation depends on it. If not a repo, offer `git init` **and make an
  initial commit** (an empty repo has no HEAD, so no worktree/branch can be created). If git is not
  installed, stop and say so.
- **Base determination.** Identify the project's main branch (docs / remote default / ask — do not
  guess). Verify `main` has no unpushed commits and the working tree has no modified/staged **tracked**
  files; if either fails, **stop and report**. Then classify:
  - **Greenfield** (main contains only an init commit or is empty beyond producer-generated
    `.dryforge/`): **base = main**. No feature branch — there is no production code to protect.
  - **Existing project** (main has meaningful committed code): **base = feature branch** created
    from main (`git checkout -b dryforge/<feature>`). Protects main from incomplete work.
  - **`.dryforge/` as untracked files** is the expected handoff state from the producer — do not
    treat it as a dirty tree. Anything else untracked or modified is foreign work → stop and report.
  - **You own the `.dryforge/` git mechanics.** On the base, add `.dryforge/` to `.gitignore` and
    commit. For existing projects this stays on the feature branch (never on main); for greenfield
    it is on main (acceptable — main has no meaningful history to protect). If a prior run left
    `.dryforge/` *tracked*, run `git rm -r --cached .dryforge/` first.
- Read **handoff first** (it governs: document roles, hard gates, execution shape), then spec and
  plan. Parse the plan's Execution Graph **per `references/graph-contract.md`** — the consumer-side
  schema (what the YAML fields mean and the rules go must hold when reading them). It mirrors the
  producers' authoring schema; if the plan's graph contradicts it, that is a producer-side defect →
  stop and escalate.

## Graph validation (before any irreversible worktree creation)

Validate the plan's Execution Graph **before creating the base** — it is cheap and safe
to fail (no git state mutated yet), so catch a malformed graph before any worktree exists to unwind.
Parse the YAML, then confirm the graph is **acyclic**, that every `depends` / `after` id **names a
real task** (no dangling reference), and that the plan body and the graph **agree on the task id set**
(no graph task missing from the plan body, none in the body absent from the graph). `graph-contract.md`
is the authoritative rule set for these checks. On any failure, **report the specific error** — which
check failed and where (the offending id / cycle / mismatch) — and the recovery: the user fixes the
plan YAML and re-runs `/dryforge:go`, which re-validates from scratch (no partial state is left behind,
since validation precedes worktree creation).

## Flow

Parse the graph → topological sort into waves (batches of **≤8 concurrent**). Set up the **base**
(per Base determination): for existing projects create the feature branch, for greenfield stay on
main. On the base, set up `.dryforge/` (copy the 3-doc, gitignore, commit). The orchestrator reads
`.dryforge/` here — task subagents do **not**; they receive spec slices inline (`orchestration.md`).
Then, per wave:

**Scaffold (inline, before dispatch).** Project initialization — manifests, dependencies, directory
layout, build config, server/client entry points, shared types — is the orchestrator's job, not a
task. On the base, perform scaffold inline: read the spec's tech decisions and set up the project so
implementers start in a working skeleton. Scaffold is not in the Execution Graph. Exception: if
scaffold itself is large enough to warrant a dedicated agent (complex infra, containers, CI pipelines
— work that requires investigation or trial-and-error), dispatch it as an implementer before the
first wave.

**Review policy (natural language, orchestrator judgment).**
Default: a single **final review** after all waves merge — one subagent checks the full diff for
spec conformance + code quality (`reviewer-prompt.md`). This replaces per-task spec-review and
per-wave code-review for most graphs. Mid-run review is added only when the orchestrator judges
that **a RISKY task with downstream dependents could cascade a deviation** — then that task gets a
spec-review before merge. The judgment comes from the Execution Graph: `risk` + `depends`.
**Lightweight fix path:** advisory findings from the final review that are trivial (1–2 files,
non-behavioral) are fixed directly on the base — no fix-dispatch subagent. The orchestrator edits,
commits, and re-runs the completion gate. Reserve fix-dispatch for substantive fixes that warrant
independent review.

**Sequential wave** (single task — the common case):

1. **Dispatch implementer** — one subagent, pinned to the base directory (verify with `git rev-parse
   --show-toplevel`). The implementer commits directly on the base. No worktree creation, no
   dependency install — the base already has everything. Right-sized verification applies
   (`implementer-prompt.md`); shared-write constraints apply.
2. **Collect** — the implementer returns a structured summary (status + files + tests + concerns);
   keep the summary only, not raw diffs.
3. **Spec review** (conditional, `spec-review-prompt.md`) — only when the review policy calls for it
   (RISKY task with downstream dependents).
4. **Verify commit** — confirm the implementer's commit landed on the base (`git log`, non-empty diff
   touching declared targets). Then run **regen barriers** and **deferred wiring** if applicable,
   committed on the base. No integration gate — the implementer's self-checks on the cumulative base
   are sufficient for a sequential wave. → next wave.

**Parallel wave** (multiple tasks — worktree isolation required):

1. **Create task worktrees** — serially (avoid `.git/config.lock` contention), each branched off the
   base. **If the project has an installable dependency tree**, install or share it (sharing guidance
   in `orchestration.md`).
2. **Dispatch implementers** — one subagent per task, in parallel, ≤8 at a time
   (`implementer-prompt.md`): right-sized verification, shared-write constraints, pinned worktree
   path.
3. **Collect** — each returns a structured summary.
4. **Spec review** (conditional) — only when the review policy calls for it.
5. **Merge serially** into the base. **Merge-gate per task (objective, not existence-only):** the task
   branch is strictly **ahead** of the base (`git rev-list base..task` non-empty) AND its diff is
   non-empty and touches declared targets — checked with three-dot diff (`git diff base...task`).
   The **merge commit message must satisfy the project's commit-msg hooks**. Then run **regen
   barriers**, then **deferred wiring** (check-before-append, idempotent; conflicts → escalate) and
   **commit wiring on the base**.
6. **Integration gate** — run the project's verify commands on the merged result **after** wiring is
   committed; **green = exit 0, output captured**. This catches cross-task interactions that no single
   implementer could see. Failure → analyze → fix-dispatch or escalate.
7. **Clean up** task worktrees — only after asserting each task's commit is an ancestor of the base
   (`git merge-base --is-ancestor`); if not, **do not remove** — escalate. Prefer safe `git worktree
   remove` (no `--force`). Remove dependency-share symlinks first (a trailing-slash ignore pattern
   does not match a symlink — use slash-less `<dir>`). Delete merged task branches (`git branch -d`).
   A failed task's worktree and branch are preserved for diagnosis. → next wave.

**After all waves:**

8. **Completion gate** — the full verify set on the base, mandatory regardless of wave types. Catches
   cross-wave interactions that sequential self-checks cannot see.
9. **Final review** — one subagent checks the **full diff on the base** (from initial state to current)
   for spec conformance + code quality (`reviewer-prompt.md`). **Clear = zero blocking findings,
   recorded.** Apply the lightweight fix path for trivial advisories; fix-dispatch for substantive
   findings.

**Advancing waves.** Sequential waves advance immediately after commit verification — no gate to
wait for. For parallel waves, the next wave's provisioning MAY overlap the current wave's
integration gate (Stream A/B/C mechanics in `orchestration.md`), but dispatch waits for a green
gate. Fall back to fully serial advance if uncertain.

Mechanics, CC dispatch constraints, status protocol, context budget, and failure handling live in
`references/orchestration.md`.

## Completion gate (avoid self-judgment A=A)

Done only when ALL hold — on **evidence**, not assertion:
- every wave merged; every spec requirement traced to a merged task; zero open
  `BLOCKED` / needs-fix. **"Zero open BLOCKED" is not "counted as done"** — each BLOCKED task must have
  **completed escalation to the user** (the user has been told and has resolved its disposition) with
  its **worktree preserved** for diagnosis; a BLOCKED task may never be silently tallied into "done".
- every `DONE_WITH_CONCERNS` concern **resolved (fix-dispatched) or explicitly accepted and
  recorded** (at code-review or by the user) — a flagged concern is never silently carried into
  "done".
- a **final full check** — **all** of the project's verify commands (whatever the stack actually has
  — e.g. typecheck / lint / test / build, or fewer; including any genuinely expensive end-only step
  deferred from the per-wave gate) on the integrated base **exit 0, with the commands and
  exit codes captured and shown** (not "looks green"). **Why re-run everything when each wave already
  passed:** a per-wave gate proves each wave green *in isolation*, but the integrated result can break
  on **cross-wave interactions** that no single wave's gate could see — so the completion gate re-runs
  the full verify set against the whole base as the final, all-together check. Running the
  full verify set every wave is the **safe baseline**; narrowing to an **affected-only** subset is an
  optional efficiency lever only where the project's tooling supports reliable impact analysis.
- no residual escalation outstanding — and any task that returned `NEEDS_CONTEXT` / `BLOCKED` was
  escalated to the user **synchronously** (the orchestrator pauses the run and waits for the user's
  response — never a silent hang or a timeout-drop). Subagents themselves never call `AskUserQuestion`
  (the prompt files carry that fresh-session rule); only the orchestrator relays escalations to the user.

## Finish

After the completion gate passes:

- **Greenfield (base = main) →** work is already on main. Notify the user that the project is
  complete on main. No merge needed.
- **Existing project (base = feature branch) →** ask the user **how to integrate**:
  - **Merge to main →** fetch and confirm main has not moved (if it has, re-integrate / escalate);
    merge the feature branch with **`--no-ff`** **from a checkout on the main branch**. **On
    conflict, abort and escalate.** After confirming the merge, clean up branches.
  - **Open a PR / push →** push the feature branch; leave integration to the project's review flow.
  - **Hand off only →** keep the feature branch intact.
  Never integrate on your own.
