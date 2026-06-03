---
name: set
description: >
  Refine and validate a {spec, plan} against the real project code, then produce an
  execution-ready 3-doc (handoff, spec, plan) for go. Use when the user invokes the `set` skill with a spec path and a plan path. Best run in the same session the spec/plan
  were drafted (live design intent can be mined), but also handles cold files brought from
  elsewhere — hand-written or from another tool. Requires git.
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, Agent, AskUserQuestion
---

# set

Refine a `{spec, plan}` into an execution-ready **3-doc** (handoff + spec + plan)
grounded in the real project code. The output is consumed by `go`. The 3-doc contract is in
`references/output-format.md`.

**Two invocation contexts** (detect which you are in, and degrade gracefully):
- **S1-live** — run in the same session the spec/plan were drafted, while the brainstorming/
  planning context is still in view. This is the richer mode: mine the live conversation for
  intent that never made it into the files (the rationale behind a decision, a constraint stated
  out loud, a rejected alternative) and inject it into the handoff.
- **Cold** — the `{spec, plan}` arrives as files from elsewhere (hand-written, or exported from
  another tool) with no live design conversation. Then the files **are** the whole input: work
  file-only, claim no S1 decision you can't see, and lean harder on escalation for any intent the
  code and docs can't settle (there is no conversation to recover it from).

Both modes converge on the same 3-doc; the difference is only *how much* un-captured intent you
have access to. Don't invent S1 intent in cold mode — that is the fabrication trap.

**Detection rule.** If the brainstorming/planning conversation that produced these docs is
visible/scrollable in THIS session's history → **S1-live** (you may mine it). Otherwise → **Cold**
(files only; never attribute intent to an unseen conversation; escalate when files can't settle
intent). Notify the user which mode was detected at the start of Phase 1.

## Core principles (apply throughout)

- **Serve the spec.** spec is ground truth (WHAT to build). plan is a provisional
  blueprint — revise it freely. Existing code is legacy: a reference for HOW and a
  reality-check for the plan's claims, never the authority for WHAT.
- **escalate-don't-guess.** Anything you cannot derive from spec/plan + project code,
  do NOT invent — ask the user.
- **Floor, not ceiling.** These phases are a proven scaffold: follow the structure, but
  use judgment inside each step. Do not hardcode verification checklists — derive
  criteria from the spec/project as needed.
- **Stack-agnostic.** Discover project specifics (build targets, regen commands,
  conventions, registration points) during GATHER; never assume a stack.

## Input & preconditions

- Invocation: the user invokes the `set` skill   with two paths in the prompt. Parse the two paths from the user's prompt text
  (whitespace- or quote-separated). Confirm **exactly two readable paths** resolved;
  if missing/unreadable, ask for them.
- **Input-validity precheck.** Confirm the spec has ≥1 **concrete requirement** and the plan has ≥1
  task with file targets. (A stub/empty plan vacuously satisfies "orphan = 0"; coverage-gap = 0 is
  only meaningful against a non-empty spec.) A **concrete requirement** = a rule/behavior/decision
  specific enough to test against — not a bare goal. If the precheck fails (stub/empty spec or plan),
  do not just stop — offer concrete recovery options and let the user pick: (a) flesh out the
  spec/plan here via targeted follow-up questions; (b) switch to dryforge `ready` for a full design
  dialogue; or (c) supply a different spec/plan path.
- **git required.** If the project is not a git repo, offer to run `git init` **and make an initial
  commit** (an empty repo has no HEAD, so go could not create a worktree). If git is
  not installed, stop and tell the user git is required (worktree isolation depends on it).
- Load the spec and plan into your own context — they are the workpiece you refine, not
  something to summarize via a subagent. For very large inputs, keep an index and edit
  section-by-section (the file is the store).

## Phase 1 — GATHER (understand the project)

**GATHER budget.** Start with a cheap inline map: repo instructions, file list, manifests,
test/verify scripts, and the paths named by the incoming spec/plan. Dispatch read-only subagents
only when the project is large enough, unfamiliar enough, or broad enough that summary isolation will
save more context than it costs. Pattern & result-compaction: `references/subagent-management.md`.
For small or tightly-scoped inputs, keep GATHER inline and targeted.

- **Scout** (first, inline or delegated): project layout, conventions, entry points. Use
  `AGENTS.md` as a guide if present; otherwise explore and tell the user you are reading broadly.
- **Pattern + Infrastructure** (in parallel, using Scout's output): existing similar
  implementations (the HOW reference) + external constraints (infra, build config, deps).
  Discover the project's verify commands here. If none surface, that is not a silent default —
  carry it forward and resolve it explicitly in RESOLVE (see below).
- **Dispatch ROI test:** each delegated read must have a bounded scope and a named question. If you
  cannot say what summary would change the 3-doc, read inline instead.

## Phase 2 — VERIFY (check + fix structure)

Per-pass rules: `references/gap-analysis.md`.

- **Pass 1 — structure** (deterministic): do the plan's paths / build targets / imports
  exist? Use targeted `rg`/`find`/project-graph commands. **Fix structural mismatches
  immediately**, so later passes run against corrected docs.
- **Pass 2 — requirements** (bidirectional trace): every spec requirement maps to a task
  (else coverage gap); every task is grounded in spec (else orphan).
- **Pass 3 — cross-consistency**: spec internal contradictions, plan inconsistencies,
  spec↔plan divergence, project-convention fit.
- If a GATHER summary is not enough to judge, dispatch a focused follow-up read (GATHER =
  broad; here = narrow).

## Phase 3 — RESOLVE (refine + ask)

Conversion & thinking-base rules: `references/refinement-rules.md`.

- **Auto-fix** (non-structural): premature code → behavioral contract; convention
  violations → project pattern; simple spec↔plan wording/cross-refs.
- **Thinking-base**: where an S2 agent could not derive a decision from code, record
  *decision + reason*. **Never fabricate** — if the reason is not on the record (stated in the
  spec/plan, or — in S1-live mode — in the live conversation), escalate to the user instead of
  inventing one. (Cold mode: the docs are the only record; don't attribute a reason to a
  conversation you can't see.)
- **Zero discovered verify commands** is itself a recorded decision, never left implicit: surface it
  and resolve to an explicit outcome — a custom check, human-approval evidence, or an explicit "none"
  — captured in the thinking-base.
- **User questions** (unresolved only): domain/scope/trade-off decisions, suspected spec
  errors. Briefly report what you auto-handled; ask only the unresolved, in priority order
  (blocking > data-integrity > missing-feature > optimization), each with a proposed answer.

## Phase 4 — GENERATE (produce the 3-doc)

3-doc contract: `references/output-format.md`. Execution Graph: `references/dependency-calc.md`.

- **handoff first** (governing doc): document roles + conflict resolution, file locations
  (project-root-relative, never machine-absolute) + execution shape, hard gates, and — **in
  S1-live mode only** — the intent surfaced in the live conversation but not captured in
  spec/plan. (Cold mode: there is no such conversation; omit this rather than invent it.)
- **spec**: finalize (auto-fixes + thinking-base + user answers + required-verification).
- **plan**: finalize (behavioral contracts + thinking-base + phase narrative + shared-write
  prose guidance).
- **Execution Graph last** (after everything else is fixed): per-task `depends`;
  top-level `regen_barriers` (schema in output-format.md). **Scaffold is not a task** — `go` performs
  project initialization inline before dispatch; do not create a scaffold task in the graph.
  Compute dependencies here — go follows them, never re-judges. As the producer, also derive
  each task's optional `risk` tier
  (`RISKY | MECHANICAL | NONE`, per the heuristic in `references/dependency-calc.md`) while
  computing the graph — it sizes the implementer's per-task test ceremony only; omit it to let the
  implementer judge risk at build time.
- Write `handoff.md`, `spec.md`, `plan.md` to `.dryforge/` and notify. **Do not touch `.gitignore`,
  and do not commit anything** — leave `.dryforge/` as plain untracked files. `go` owns the git
  mechanics: it ignores `.dryforge/` on its own feature branch when it runs (and untracks a
  `.dryforge/` left tracked by a prior run), so `main` is never modified or made ahead of its remote
  by set. Then notify: "invoke the `go` skill to execute."
- **Tell the user to tidy the source `{spec, plan}` inputs.** If those input files live *inside* the
  repo as untracked files, they are **not** under `.dryforge/`, so go's clean-tree precondition will
  see them as foreign untracked work and stop. In the notify message, advise moving them out of the
  repo or adding them to `.gitignore` before running go (set must not delete the user's inputs
  itself — just surface it).

## Completion gate (avoid self-judgment A=A)

Done only when BOTH hold:

- **Deterministic 0-signals**: coverage gaps = 0, orphan tasks = 0, structural mismatches = 0.
- **Fresh-agent probe**: dispatch a subagent that has NOT seen the brainstorming; give it
  only the 3-doc (it may read project code = the S2 environment) and ask what would block
  execution or what it would need to ask — have it **return a structured list of residual
  blockers/questions**. Point it explicitly at the **output / interface contract** too (the
  data model's entities/fields + constraints, response/output keys, status/enum value sets,
  uniqueness rules where the spec defines any) — a half-pinned contract is a recurring late-caught
  gap that blocks downstream work even when behavior reads clear. Residual → escalate to the user
  (do not self-fill). Empty → done.
