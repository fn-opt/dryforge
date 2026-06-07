---
name: ready
description: >
  From a natural-language goal, interactively elicit intent and produce an execution-ready
  3-doc (handoff, spec, plan) for go — replacing third-party brainstorming + planning
  in one skill. Use when the user invokes the `ready` skill with a goal.
  Requires git.
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion
---

# ready

> **Reply in the user's language, from your first message.** Every line you write — grounding,
> progress notes, questions, and the 3-doc — goes in the language the user is communicating in,
> written natively (never translationese). These instructions are in English; your output is not.
> Full rule in Core principles below.

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
- **Harness-aware, two modes.** Detect a project harness at EXPLORE (a `CLAUDE.md` carrying the
  dryforge structure **and** a `docs/` directory). **Later cycle** (harness present): load it as
  project context and don't re-ask what it answers — but if this task may conflict with a harness
  decision, surface the conflict to the user rather than resolving it yourself. **First cycle** (no
  harness): run the first-cycle design system (SCOPING → DESIGN, Phases 1a/1b) before task-level
  ELICIT. ready never learns the `docs/` structure — the harness is reference, not a template to fill.
- **Match the user's language (language-agnostic).** Like stack-agnosticism, the *method* is fixed
  and the *specific language* is discovered at runtime, never assumed: produce every user-facing
  output — the dialogue **and the 3-doc** — in the language the user communicates in, written
  **natively** (as a fluent speaker of that language would, never translationese). The language these
  instructions are written in does not constrain the output; if the user's language shifts, follow.
- **Talk to the user only when needed, in plain words — default to silence on process.** Emit
  user-facing text only for: (a) a question you genuinely need answered, (b) the final result or a
  concise summary, (c) a real blocker — optionally prefixed by a one-line, user-meaningful heading
  for the current step. Nothing else: don't narrate *what* you're doing, *how*, or *why* a step is
  needed; don't expose internal mechanics (reference/file names, phase/mode/lens labels, "loading
  references", "Read N files"). Write what you do say in a **plain, non-technical register** — the
  words a non-engineer would understand. This is your default voice, not a per-line check, so it
  costs nothing. **Never surface internal tokens:** dryforge mechanism / coined terms (wave,
  worktree, harness, delta, 3-doc, gate, seam, ROI collapse, spec-review, grounding, lens,
  invariant), task / step / risk labels (`T1`, `Wave 2`, RISKY / MECHANICAL / NONE), or
  project-internal jargon a non-engineer wouldn't recognize (library/tool names, config flags,
  test-framework internals). **Don't soften internal logic into user-ish words — just omit it.** E.g.
  "Starting a git repo here." — not "Since go will later need git for worktrees, I'll initialize one
  (non-destructive setup)."

## Input & preconditions

- Invocation: the user invokes the `ready` skill with a natural-language goal. Treat the user's prompt text as the goal; if
  it is empty or only says to use the skill, ask what they want to build or change.
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

**Harness detection (first).** Check whether a project harness exists: a `CLAUDE.md` carrying the
dryforge structure **and** a `docs/` directory. If it exists, this is a **later cycle** — load
`CLAUDE.md` and the relevant `docs/` files as project context, pre-resolve anything the harness
already answers (don't re-ask it), and if this task may conflict with a harness decision, identify
the conflict (trade-off? defect? intentional change?) and **ask the user** — domain conflicts don't
self-resolve. If it does **not** exist, this is the **first cycle** — run Phases 1a/1b (the design
system) before ELICIT. ready uses the harness only as reference; it does not know the `docs/`
structure.

If an existing codebase is in scope, read enough to ground every later decision: conventions, the
public contract relevant to the goal, existing patterns the change must fit, and the test/verify
harness. Read the project directly (Read, Bash, Grep) — no subagent dispatch. For greenfield
(no code yet), this is minimal or skipped — the conception and dialogue carry it.

**Exploration budget.** Start with the cheapest project map: repo instructions, file list, manifests,
test/verify scripts, and only the directories named by the goal. Stop broad reading as soon as Gate 1
is satisfied. Deep-read only the files needed to pin the contract, one representative HOW pattern,
and the verification commands. For low-blast-radius changes, a tiny 3-doc is better than a fully
ornate one; spend effort on intent correctness, not archive-quality prose.

Run autonomous enumeration here: the questions a careful reviewer would raise, with the ones the
goal/code already settle **pre-resolved** (so ELICIT spends the user's attention only on what they
uniquely hold). **Gate 1:** for an existing project you can state the goal's blast radius, the
contract to honor, and the verify commands; for greenfield you have a grounded conception — else
keep reading. If the project/goal has **no automated verify commands**, that absence is itself a
decision to surface (a custom check, named human-approval evidence, or an explicit "no automated
gate") — never left implicit, so go's gate is never undefined.

## Phase 1a — SCOPING (first cycle only) — `references/project-scoping.md`

**First cycle only.** Force-load `references/project-scoping.md`. Establish the project's character
(identity, scale, hard constraints) and confirm it with the user — this sets the depth of everything
downstream. Tell the user where you are and why (this is designing together, not an interrogation).
Form a tentative read, update it through dialogue, then present the final read + depth direction and
get confirmation before DESIGN. YAGNI gate: surface (don't silently cut) a design heavier than the
project warrants.

## Phase 1b — DESIGN (first cycle only) — `references/project-design-domain.md`, `references/project-design-technical.md`

**First cycle only.** Force-load the two design references in order. **Domain first**
(`project-design-domain.md`): extract the domain model from the user — entities, rules, invariants,
edge cases — to the depth/breadth floor (domain is always deep, even for a small project). **Then
technical** (`project-design-technical.md`): present architecture / security / convention /
operations decisions as options + trade-offs and let the user decide (no silent decision). At each
phase transition, tell the user what's done and what's next.

## Phase 2 — ELICIT (interactive dialogue — the heart)

**First cycle:** ELICIT runs *after* SCOPING+DESIGN — it elicits *this task's* intent on top of the
confirmed project foundation, not the whole project again. **Later cycle:** ELICIT runs right after
EXPLORE, using the harness as context.

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
Keep the spec dense: every section earns its place by constraining implementation or review. Avoid
repeating project facts that `go` can read again cheaply.

## Phase 4 — REVIEW (intent-incompleteness probe @ spec, autonomous)

Full guidance: `references/intent-review.md`. Probe the frozen spec for what the dialogue missed —
an independent reader pointed at completeness, **risk-proportional** (aim at the assumptions /
non-derivable decisions; depth scales with stakes). Split findings: internally-resolvable → fix in
spec; **user-only intent-gap → reopen ELICIT and ask** (never auto-fix a guess). **Degrade mode:**
no nested subagent → deliberately-separate self-adversarial pass. **Gate 5:** no blocking intent-
gap remains (all fixed or user-answered). Only now build the plan.

**First cycle:** additionally force-load `references/first-cycle-review.md` and run it alongside the
intent probe — it checks the spec + Foundation are a sufficient *project* foundation (domain
depth/breadth, technical decisions closed, security project-specific, no vague modifiers). A
foundation gap only the user can fill reopens the matching DESIGN phase (1a/1b); never auto-fill it.

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
Prefer fewer, larger tasks when splitting would only add merge/review overhead and no real
parallelism. Prefer more tasks only when targets, dependencies, and verification evidence are truly
independent. The graph should maximize useful concurrency, not task count.

## Phase 6 — HANDOFF (governing doc) + output

Write `.dryforge/handoff.md` — the governing doc (3-doc contract: `references/output-format.md`):
document roles + conflict resolution, file locations (project-root-relative), hard gates, and the
**intentionality captured live in dialogue** that is not in spec/plan. Because produce captures
intent directly (not reverse-engineered from foreign docs), this handoff should be richer.

**First cycle:** force-load `references/foundation-format.md` and include a **Project Foundation**
section in the handoff — the project-wide foundation from SCOPING/DESIGN (identity; the full domain
model with `[implementation target]` / `[project context]` labels; the confirmed technical
decisions; future scope), clearly labeled as **non-executable project context**. `go` reads it as
context while implementing this task's spec, and as the source for the harness it creates at the end.
Omit the Foundation in later cycles (the harness has taken over the project-context role).

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

On approval, notify the user clearly:
- What was produced (3-doc at `.dryforge/`).
- **How to execute:** "invoke the `go` skill **in this session** to execute." Produce → run is a
  single session — the design context carries straight into execution (and into the harness `go`
  builds at the end).
- **The 3-doc is the authority.** `go` executes against the 3-doc (kept self-sufficient because it is
  archived for later cycles); the live design context aids `go`'s judgment but the 3-doc, not the
  dialogue, is the contract.
