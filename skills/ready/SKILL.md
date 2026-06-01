---
name: ready
description: >
  From a natural-language goal, interactively elicit intent and produce an execution-ready
  3-doc (handoff, spec, plan) for go — replacing third-party brainstorming + planning
  in one command. Use when the user runs /dryforge:ready with a goal. Requires git.
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion
---

# ready

The **front door** of dryforge. Turn a natural-language goal ("I want to build / change X") into
an execution-ready **3-doc** (handoff + spec + plan), grounded in the real project code, ready for
`go`. This is the *native* path: it elicits intent through dialogue and authors the pair
itself — one command, no third-party brainstorming/planning plugin.

Sibling entry point: `set` does the same for a `{spec, plan}` that **already exists**
(brought from elsewhere) — surgical grounding of foreign input. Both converge on the same 3-doc,
which `go` (the destination) consumes. The 3-doc contract is in
`references/output-format.md`.

## Core principles (apply throughout)

- **Serve the spec.** The spec is the contract — the binding WHAT, ground truth. The plan is a
  *provisional blueprint* that realizes it (revise freely; not the authority). Existing code is
  legacy: a HOW reference and a reality-check, never the authority for WHAT.
- **Ask, don't assume — but don't ask the derivable.** Actively elicit what only the user holds
  (intent, preferences, load-bearing choices). What the goal/code settles, resolve yourself.
  Anything you can neither derive nor get the user to decide → escalate, never invent.
- **Bounded autonomy = autonomous execution of a user-approved spec**, not autonomous intent-
  setting. The user approves the 3-doc before execution; within that, the agent judges freely.
- **Floor, not ceiling.** These phases are a proven scaffold: follow the structure, use judgment
  inside. Do not hardcode question lists or verification checklists.
- **Stack-agnostic.** No stack/framework/library name in this skill. Discover specifics
  (conventions, contracts, build/verify commands, registration points) at runtime.
- **No subagents.** ready runs entirely in the main session. EXPLORE, SPEC, PLAN, HANDOFF,
  and the intent-incompleteness probe are all inline. Context protection is not worth the
  dispatch overhead — the main session already holds the dialogue context that grounds
  every decision.

## Input & preconditions

- Invocation: `/dryforge:ready <goal>`. The goal is natural language (not a file).
  Parse it from `$ARGUMENTS`; if empty, ask the user what they want to build or change.
- **git required.** If the project is not a git repo, offer to run `git init` **and make an initial
  commit** (an empty repo has no HEAD, so go could not create a worktree later). Worktree
  isolation in go depends on git. If git is not installed, stop and say so. This holds for
  both greenfield (0→1) and existing projects — code presence is *not* the deciding factor.
- **Output location.** The 3-doc is written to `.dryforge/` at the project root as plain files. You
  do **not** touch `.gitignore` and do **not** commit anything — `go` owns all git mechanics for
  `.dryforge/` (it ignores the docs on its own feature branch when it runs). Keep the
  produce=plan / run=do boundary: produce writes documents, run touches git.

## Phase 0 — INTAKE

From the goal, form a reasonable, standard, YAGNI-sized rough conception immediately (the starting
point you will refine through dialogue). Note whether an existing codebase is in scope.

Also read the goal's **task type** — greenfield / feature-add / refactor-no-new-scope / docs-config
— and let it set ELICIT depth. A low-blast-radius, zero-new-contract goal (a one-line change, a
docs or config edit, a refactor introducing no new behavior) **downshifts** the dialogue: don't
over-interrogate functional intent that isn't there — still emit a skeletal-but-VALID 3-doc (every
section present, gates met, just lighter). A substantive goal keeps the full "ask deeply about
functional intent" depth below. This is a runtime judgment of where the goal actually sits, not a
hardcoded skip list.

## Phase 1 — EXPLORE (conditional; ground before deciding)

If an existing codebase is in scope, read enough to ground every later decision: conventions, the
public contract relevant to the goal, existing patterns the change must fit, and the test/verify
harness. Read the project directly (Read, Bash, Grep) — no subagent dispatch. For greenfield
(no code yet), this is minimal or skipped — the conception and dialogue carry it.

Run autonomous enumeration here: the questions a careful reviewer would raise, with the ones the
goal/code already settle **pre-resolved** (so ELICIT spends the user's attention only on what they
uniquely hold). **Gate 1:** for an existing project you can state the goal's blast radius, the
contract to honor, and the verify commands; for greenfield you have a grounded conception — else
keep reading. If the project/goal has **no automated verify commands**, that absence is itself a
decision to surface (a custom check, named human-approval evidence, or an explicit "no automated
gate") — never left implicit, so go's gate is never undefined.

## Phase 2 — ELICIT (interactive dialogue — the heart)

Full guidance: `references/elicitation.md`. In short: lead with a recommendation; ask **deeply**
about functional intent (behavior, edge cases, invariants, scope); **default-and-surface** load-
bearing technical decisions (state the trade-off, one beat, overridable — never silent); silently
default the trivial. Don't ask what you already derived. **Gate 2:** transition gate — the user
says enough (unless a material gap remains), or nothing is left for the user to decide.
**Mandatory:** for greenfield (or when
EXPLORE did not fix the stack), you must surface the load-bearing **technical shape** (persistence,
interface/delivery form, anything the whole plan rests on) before SPEC — an un-surfaced technical
shape is a material gap that blocks the gate. Stop via the transition gate (user says enough —
unless a material gap remains — or nothing is left for the user to decide).

## Phase 3 — SPEC (write the ground truth)

Write `.dryforge/spec.md` — WHAT, not HOW. Restate the goal; include objective + motivation;
**invariants / preserved contract** (the load-bearing section); the substantive behavior/rules;
scope boundaries; and **explicit assumptions / decisions+rationale** for everything not code-
derivable (the thinking-base — and the visible record that makes a missed item cheap to catch).
The spec is the contract; keep premature implementation out. If EXPLORE found no automated verify
commands, record the surfaced gate decision (custom check / named human-approval evidence / explicit
"no automated gate") here as one of those decisions — so go's gate is never undefined. **Gate 3:** spec covers every
elicited question; every invariant is concrete/checkable; rationale present for each non-derivable
decision; no silent assumption (record it or ask).

## Phase 4 — REVIEW (intent-incompleteness probe @ spec, autonomous)

Full guidance: `references/intent-review.md`. Probe the frozen spec for what the dialogue missed —
an independent reader pointed at completeness, **risk-proportional** (aim at the assumptions /
non-derivable decisions; depth scales with stakes). Split findings: internally-resolvable → fix in
spec; **user-only intent-gap → reopen ELICIT and ask** (never auto-fix a guess). **Degrade mode:**
no nested subagent → deliberately-separate self-adversarial pass. **Gate 5:** no blocking intent-
gap remains (all fixed or user-answered). Only now build the plan.

## Phase 5 — PLAN (decomposition for parallel execution)

Load `references/output-format.md` (the 3-doc contract) and `references/dependency-calc.md` (the
Execution Graph) before authoring — write to the actual schema go parses, not from memory.
Write `.dryforge/plan.md` from the frozen spec. Per task: a **behavioral contract** (goal, file
targets, verification gate tied to the Phase-1 harness), the thinking-base where not code-derivable,
and shared-write guidance (prose). Then compute the **Execution Graph** last
(`references/dependency-calc.md`) — the only machine-binding part of the plan; go follows
it and never re-judges. As part of authoring that graph, the producer derives each task's optional
**RISK tier** (`risk: RISKY | MECHANICAL | NONE`, per `references/dependency-calc.md`), so the
3-doc the user reviews carries it. **Scaffold is not a task.** `go` performs project initialization
(manifests, dependencies, directory layout, build config) inline before dispatching implementers —
do not create a scaffold task in the plan. Keep the produce=plan / run=do boundary. **Gate 6:** every spec
requirement maps to ≥1 task (forward trace); every task grounds in a spec requirement (no orphan);
the verification gate is named.

## Phase 6 — HANDOFF (governing doc) + output

Write `.dryforge/handoff.md` — the governing doc (3-doc contract: `references/output-format.md`):
document roles + conflict resolution, file locations (project-root-relative), hard gates, and the
**intentionality captured live in dialogue** that is not in spec/plan. Because produce captures
intent directly (not reverse-engineered from foreign docs), this handoff should be richer.

Write the three docs to `.dryforge/` and notify. **Do not touch `.gitignore`, and do not commit
anything** — leave `.dryforge/` as plain untracked files. `go` owns the git mechanics: when it
starts, it ignores `.dryforge/` on its own feature branch (and untracks a `.dryforge/` left tracked
by a prior run), so the project's `main` is never modified, and never made *ahead of its remote*,
by produce. Centralizing all git in the run side is what keeps this handoff seam clean.

## Final gate (the one human checkpoint — G7)

Present the 3-doc to the user: *"Review this and confirm. If it's right, proceed; if not, tell me
and I'll fix."* This is not a violation of one-command autonomy — autonomy is executing an
**approved** spec, not setting intent. One gate, at the end. (The only mid-run question is the
Phase-4 exception: a genuine user-only intent-gap.)

## Completion gate (avoid self-judgment A=A)

Done only when BOTH hold:
- **Deterministic 0-signals:** coverage gaps = 0, orphan tasks = 0, Execution Graph parses.
- **Intent-incompleteness probe (Phase 4) clear:** no residual blocking intent-gap. Residual →
  escalate to the user (do not self-fill).

On approval, notify: "run `/dryforge:go` to execute."
