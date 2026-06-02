# orchestration.md — wave lifecycle (force-load)

The mechanics behind the SKILL's per-wave flow: scheduling, dispatch constraints, status handling,
context budget, and failure handling. Loaded for the whole run. The wave lifecycle is a proven
scaffold — keep its structure and the safety constraints; use judgment inside each step.

## Reporting principle

User-facing text = wave completion, blockers, final results. Internal operations (merge, gate,
worktree lifecycle, branch cleanup, dependency install) produce **no text output**. Output tokens
are direct cost.

## Wave scheduling

- Topologically sort the plan's `depends` into waves: a wave = tasks with no unmet dependency.
- **Classify each wave:** single task = **sequential**; multiple tasks = **parallel**.
- **Sequential wave:** implementer works directly on the base (no worktree, no dependency install,
  no integration gate). The implementer commits on the base; the orchestrator verifies the commit
  and advances immediately.
- **Parallel wave:** task worktrees branched from the base; ≤8 concurrent. Integration gate after
  merge catches cross-task interactions.
- **Batch ≤8 concurrent.** If a parallel wave has more than ~8 tasks, split into sub-batches.
- Do not recompute or reorder dependencies — the producer owns the graph. Parse failure / cycle /
  dangling `depends` → **stop and escalate** (producer-side defect).

## Sequential wave — dispatch constraints

- **Pin the implementer to the base directory** — omit `isolation: worktree`; verify location with
  `git rev-parse --show-toplevel`. The implementer commits directly on the base.
- **Verify the commit after return** — `git log` shows a new commit, and `git diff HEAD~1` touches
  the task's declared targets. Never trust the subagent's self-report.
- **No integration gate** — the implementer's self-checks (typecheck/lint/test/build per risk tier) run on
  the cumulative base, which already includes all prior waves. Cross-task interaction risk is zero
  (single task). The completion gate catches cross-wave interactions at the end.
- **Restore the orchestrator's cwd** — subagent runs can drift it.
- **Subagent output is bounded** — instruct large results to a file + a digest, not inline.

## Parallel wave — dispatch constraints (safety, non-negotiable; unordered)

- **Do not pass `isolation: worktree` to implementer dispatch** — omit isolation so the
  implementer runs in place, **pinned to the pre-created absolute worktree path**, and verify
  location with `git rev-parse --show-toplevel` at the subagent's start.
- **Create worktrees serially** — concurrent `git worktree add` contends on `.git/config.lock`.
  **Worktree pool:** when multiple parallel waves exist, create the maximum number of worktrees
  needed by any single wave **once** before the first parallel wave. Between waves, reset a
  pooled worktree with `git checkout <new-base-tip> && git reset --hard` instead of
  remove + recreate. Gitignored symlinks (dependency shares) survive `reset --hard`. After all
  waves complete, **clean up all pooled worktrees in one batch** (not per-wave). This avoids
  repeated create/remove cycles across waves.
- **Task worktrees do not contain the 3-doc.** `.dryforge/` is gitignored, so a freshly-added task
  worktree has **no** `spec.md` / `plan.md` / `handoff.md`. Pass every spec slice, task contract,
  and hard gate **inline in the subagent prompt**.
- **Verify the work before merging (objective, not existence-only)** — the task branch must be
  strictly *ahead* of the base (`git rev-list base..task` non-empty) AND its diff non-empty and
  touching declared targets — checked with **three-dot** diff (`git diff base...task`).
- **Restore the orchestrator's cwd after each wave.**
- **Subagent output is bounded.**
- **Practical parallelism ~5–8.**
- **Don't disable the build cache or daemon.** Warm it once and share across worktrees.
- **Enable incremental / caching mode at scaffold** when the project's build or verify tools
  support it but default to off. Check the tool's config or documentation during scaffold setup;
  if an incremental or cache option exists, enable it. Repeated verify runs (per-wave gates,
  completion gate) benefit from warm caches. This is the orchestrator's scaffold responsibility,
  not a per-task concern.
- **Share dependencies; don't reinstall per worktree.** Symlink/reflink external deps; relink
  workspace-internal packages to this worktree's own source. **Caveat — path-mapping monorepos:**
  per-worktree install from the warm store is the safe default; don't force symlink sharing.
  **Cleanup caveat:** a dependency-store symlink is untracked; ignore it with a **slash-less**
  pattern (`<dir>`, not `<dir>/`); remove the symlink before safe-removing the worktree.
- **Slash-less gitignore — verify at scaffold, before any worktree.** After scaffold commits,
  confirm `.gitignore` uses slash-less patterns for dependency directories (the project's dependency
  store directory, without a trailing slash). A trailing-slash pattern does not match a symlink, so
  worktree dependency symlinks get staged by `git add`. Fix this **before** creating the first
  parallel wave's worktrees — every worktree agent will otherwise hit the same papercut
  independently.
- **Worktrees isolate *files*, not *runtime*.** Shared external resources (DB, cache, queue, ports)
  are shared across all tasks. Treat mutations as dangerous; on unexpected state drift, **stop and
  escalate**.
  - **Declared shared-resource expectations** (clean-slate / state-agnostic / additive-only /
    forbidden-mutations) are honored per the producer's dependency-calc rules.
  - **Ordering / external-state deps** — Go honors explicit `depends` and serializes declared
    external-state writers.

## Agent status protocol

Each implementer returns one status:

| Status | Meaning | Orchestrator response |
|---|---|---|
| `DONE` | complete, self-checks pass | spec-review → merge |
| `DONE_WITH_CONCERNS` | complete, but flags something | record the concern; weigh at final review (or mid-run spec-review if review policy triggers it) |
| `NEEDS_CONTEXT` | missing info to proceed | provide the missing context, re-dispatch |
| `BLOCKED` | cannot proceed (conflict, ambiguity) | analyze; walk the bounded escalation ladder (below), then **escalate to the user** |

**Bounded escalation ladder** (for `BLOCKED` / `NEEDS_CONTEXT`): **attempt 1** — re-dispatch with
more context (the missing slice, the resolved ambiguity); **attempt 2** — re-dispatch with an
upgraded model; if it is **still BLOCKED**, **escalate to the user** with full context: what was
tried, what each attempt produced, and why it failed. The budget is bounded — do not loop
re-dispatching past the ladder.

## Context budget

- **Resident**: the 3-doc (~1–3K) + wave schedule + accumulated per-task summaries
  (~100–200 tokens each) + spec-review verdicts (~20 tokens each).
- **Temp-load → use → drop**: authoring an implementer prompt (the relevant plan+spec slice),
  analyzing a failure (the error output). Drop after the judgment.
- Keep raw diffs out of the orchestrator — spec review runs in the subagent's context.
- **Watch retry bloat**: temp-loads have per-item caps but no total cap; repeated failures can
  swell the orchestrator. Compress to summaries and drop promptly.

## Per-wave step order

> **Review policy.** Default: a single **final review** after all waves merge — one subagent
> checks the full base diff for spec conformance + code quality. Mid-run spec-review is added only
> when the orchestrator judges that a **RISKY task with downstream dependents** could cascade a
> deviation. When dispatched, spec-review is always a subagent (never inline) to preserve
> independence.

### Sequential wave (single task)

1. **Verify commit** — confirm the implementer's commit landed on the base (`git log`, non-empty diff
   touching declared targets). Never trust the self-report.
2. **Regen barriers** — run barriers whose `after` is now satisfied. Commit regenerated output if a
   later task depends on it. Recovery: if a barrier exits non-zero, capture command + exit + stderr,
   analyze whether a prior merge broke a precondition; if it would overwrite merged files, escalate.
3. **Deferred wiring** — if applicable, the single writer appends shared registrations directly
   (no parallel siblings to collide). Commit on the base.
4. **Spec review** (conditional) — only when the review policy calls for it.
5. **No integration gate.** The implementer's self-checks ran on the cumulative base. → next wave.

### Parallel wave (multiple tasks)

1. **Merge serially** into the base (commit-existence verified first). **Merge-gate:** task branch
   strictly ahead, diff touches declared targets (three-dot). Merge commit must satisfy hooks.
   Recovery: inspect hook output, verify branch state, retry with discovered convention; else escalate.
2. **Regen barriers** — same as sequential. Commit if downstream depends on it.
3. **Deferred wiring** — the single writer appends all registrations, **idempotently**
   (check-before-append; conflicts → escalate). **Commit on the base** — uncommitted wiring is
   silently lost to later worktrees and the final merge.
4. **Integration gate** — run the project's verify commands on the merged + wired base; **green =
   exit 0, output captured**. This catches cross-task interactions. Failure → fix-dispatch or
   escalate. **If the producer found zero verify commands**, the absence of a gate is a recorded
   decision, not silence. **Record the base tip SHA after the gate passes** (e.g. `GATE_SHA=$(git rev-parse HEAD)`) — the
   completion gate compares against it to avoid redundant re-runs (see SKILL.md, Completion gate). **Run verify commands in parallel** when they are independent — capture each exit code separately
   so failure attribution is clear. Wall time = max(commands), not sum. Pattern: issue all verify
   commands in a single Bash call, backgrounding each and collecting its exit code individually
   (e.g. `cmd1 & p1=$!; cmd2 & p2=$!; wait $p1; e1=$?; wait $p2; e2=$?`), then report per-command
   pass/fail.
5. **Spec review** (conditional) — only when the review policy calls for it.
6. **Clean up** task worktrees — only after asserting ancestor (`git merge-base --is-ancestor`).
   Safe remove (no `--force`); remove share-symlinks first. Delete merged task branches.
   Failed tasks' worktrees preserved for diagnosis. → next wave.

### Advancing waves

**Sequential waves advance immediately** — no gate to wait for, so the next wave can begin as
soon as the commit is verified and regen/wiring are done.

**Parallel waves:** the next wave's provisioning (worktree creation + dependency share) SHOULD
overlap the current wave's integration gate — begin provisioning as soon as the merge + wiring
commits land, before the gate finishes. The next wave's **dispatch still waits for a green gate**,
but the worktrees and dependencies are already ready. On gate failure the provisioned worktrees
are harmless (no task work yet) — remove or reuse after the fix. Fall back to fully serial advance
only if lock contention or refresh bookkeeping makes overlap unsafe.

**Advisory findings are recorded, never dropped.** Findings not fix-dispatched must be explicitly
marked accepted — never silently dropped.

### Fix-dispatch and lightweight fix

**Substantive fix-dispatch** (bugs, review blocking findings): dispatched as a subagent on a branch
off the base — reuse a task worktree if present, else create a fresh one. The subagent commits;
the orchestrator merges back under the same merge-gate.

**Lightweight fix** (trivial advisory findings — 1–2 files, non-behavioral): the orchestrator MUST
triage each advisory after the final review. Trivial (1–2 files, non-behavioral — e.g. a missing
attribute, a test warning, a one-line comment) → edit directly on the base, commit, re-run the
completion gate. The default disposition is lightweight fix, not "accepted." Only mark an advisory
as accepted when a fix is genuinely inappropriate (design trade-off, spec-intentional behavior).
Do not skip advisories as "accepted" when a lightweight fix would take seconds. This is the
exception to "the orchestrator does not edit task code" — scoped to trivial, non-behavioral
changes only.

## Failure handling

| Failure | Response |
|---|---|
| `BLOCKED` / `NEEDS_CONTEXT` | walk the bounded ladder: attempt 1 more context → attempt 2 upgraded model → escalate |
| max retries exceeded | **escalate to the user + preserve the worktree for manual recovery** (do not discard) |
| mid-run spec-review fail | re-dispatch with the specific fix |
| final review fail | fix-dispatch the blocking findings, re-run final review |
| merge conflict | analyze; resolve if mechanical / same-intent, else escalate |
| merge commit-msg hook rejection | inspect hook name + full output; verify branch state (`git log`); retry with the producer-discovered commit convention; else escalate with hook name + error + attempted message + branch state |
| regen-barrier non-zero / conflicting output | capture command + exit + stderr; analyze whether a prior merge broke a precondition; if it would overwrite merged files, escalate |
| deferred-wiring conflict | capture file + conflicting lines + involved tasks; escalate (never auto-pick a winner) |
| integration gate fail | analyze → identify the causing task → fix-dispatch |
| code-quality issue (final review) | fix-dispatch |
| architecture mismatch / suspected spec violation / data-corruption risk | **stop and escalate** |

- **Partial wave failure — cleanup order + retry semantics**: keep the merged successful tasks.
  **Preserve the failed task's worktree for diagnosis** (do not clean it). **Clean up only the
  successful worktrees**, and only after the ancestor check (`git merge-base --is-ancestor`).
  **Never delete the base.** On retry, create a **FRESH worktree branched from the
  CURRENT base tip** — which now includes this wave's already-merged successes (the base tip
  advances per merge), so the retry builds on the integrated state, not the stale pre-wave tip. The
  wave doesn't proceed until all pass.
- **Safety net**: worktree isolation means a discarded failed task never affects the base.
  Verify real work exists (`git log` / `git diff`) before relying on a result.

## Escalate = ask the user

Anything you can't safely resolve — architecture mismatch, suspected spec violation,
unresolvable conflict, data-corruption risk — **stop and ask the user.** Don't guess; the spec
is ground truth and only the user changes it.

**Escalation is synchronous.** The orchestrator→user escalation **pauses** the run and waits for
the user's answer — it never silently hangs, fires-and-forgets, or proceeds on an assumption while
"waiting." (Subagents run in fresh sessions with no live user conversation, so they cannot ask the
user; they return their escalation through their structured result, and the orchestrator relays it
to the user synchronously.)

**Detection ≠ diagnosis.** Spotting that something broke is not the same as correctly
attributing *why*. A confident but wrong cause-attribution is possible — verify it against the
actual commands and output (not a self-report or a shallow grep) before acting destructively or
recording it as a durable fact. A misattribution that gets written down propagates.
