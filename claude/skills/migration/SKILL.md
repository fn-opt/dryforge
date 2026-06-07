---
name: migration
description: >
  Convert an existing project into the dryforge documentation system: read the codebase,
  elicit what code can't reveal, and generate a project harness (CLAUDE.md / AGENTS.md +
  docs/ + per-module AGENTS.md). Use when the user invokes the `migration` skill on an
  existing project. Requires git.
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion
---

# migration

> **Reply in the user's language, from your first message.** Every line you write — grounding,
> progress notes, questions, and the harness — goes in the language the user is communicating in,
> written natively (never translationese). These instructions are in English; your output is not.
> Full rule in Core principles below.

Convert an existing project into the dryforge **project harness** — the durable documentation layer
that every later agent (dryforge or not) works inside. migration reads the codebase, elicits the
intent/constraints/decisions that code cannot express, and generates the whole harness:
`CLAUDE.md` / `AGENTS.md`, the `docs/` set, and a per-module `AGENTS.md`. The harness spec is in
`references/harness-format.md`.

migration is a **one-time conversion**, not a task runner. It writes documentation only — it does
**not** create a 3-doc (that is `ready`/`set`'s job) and does **not** execute code (that is `go`'s).
After it finishes, clear the session before running `ready`/`set` → `go`: migration is an
independent piece of work, and a fresh session keeps the task-level dialogue clean.

## Core principles (apply throughout)

- **The harness is durable project memory, not ground truth.** It is the project's discipline and
  constraint — written so the next agent works the project without going off the rails. A hollow
  harness (structure present, content empty) is worse than none.
- **Content density is the whole point.** Every file must clear the quality bar in
  `references/harness-format.md` (five principles, four techniques). Filling sections is not the
  goal; informing the next agent is.
- **Knowledge asymmetry drives elicitation.** Domain knowledge lives with the user — *extract* it
  (don't fabricate). Technical knowledge lives with you — *present* options + trade-offs and let the
  user decide. Don't accept the user's generalities as-is, and don't concretize them alone.
- **No subagents.** migration runs entirely in the main session — SCAN, ELICIT, GENERATE, and REVIEW
  are all inline. The live conversation grounds every judgment; dispatch would only strip that
  grounding.
- **Stack-agnostic.** No stack/framework/library name in this skill. Discover all specifics
  (conventions, module boundaries, build/verify commands, external deps) at runtime from the project.
- **escalate-don't-guess.** What the code can't settle and you can't derive, ask the user — never
  invent a domain rule, a policy, or a rationale.
- **Match the user's language (language-agnostic).** Like stack-agnosticism, the *method* is fixed
  and the *specific language* is discovered at runtime, never assumed: produce every user-facing
  output — the dialogue **and the whole harness** (CLAUDE.md / AGENTS.md, docs/, module AGENTS.md) —
  in the language the user communicates in, written **natively** (as a fluent speaker of that language
  would, never translationese). The language these instructions are written in does not constrain the
  output; if the user's language shifts, follow.
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

- Invocation: the user invokes the `migration` skill, no arguments — migration reads the **current
  project**.
- **Existing codebase expected.** migration converts a project that already has code. For a
  greenfield project (no code yet), there is nothing to migrate — direct the user to `ready` (which
  designs the project's first cycle and lets `go` create the harness from scratch).
- **git required.** If the project is not a git repo, offer to run `git init` **and make an initial
  commit** (later `go` needs a HEAD for worktrees). If git is not installed, stop and say so.
- **git posture — migration writes files, it does not commit.** migration creates the harness files,
  backs up any existing entry file to `.dryforge/backup/`, adds `.dryforge/` to `.gitignore` (so the
  local marker and backups aren't accidentally committed), and writes the `.dryforge/status.json`
  marker on completion. It performs **no commits and no branch operations** — whether and when to
  commit the harness is the user's choice. (This differs from `ready`/`set`, which never touch
  `.gitignore`: migration may not be immediately followed by `go`, so it sets up the ignore itself.)

## Phase 1 — SCAN (build the technical map)

Read the project inline (Read, Bash, Grep) — no subagent dispatch. Start with the cheapest map and
stop once you can ground ELICIT's questions; deep-read only where you must.

Cover:
- **Directory structure** → identify the tech stack and the module/service boundaries.
- **Code patterns** → conventions, naming, test structure, build system.
- **Existing docs** (CLAUDE.md, README, docs/, AGENTS.md, …) → list them and **demote to reference
  material** (not authority — they may be stale or wrong).
- **External dependencies** → auth, data storage, cache, external APIs.
- **git history** → activity scope, the major change patterns.

Result: a technical map of the project. This is the basis from which ELICIT generates its questions
— each discovered element (a module, a pattern, security code, an architecture, a gap) becomes a
question.

## Phase 2 — ELICIT (collect what code can't reveal) — `references/migration-elicit.md`

**Force-load `references/migration-elicit.md`.** Using the SCAN map, ask the user for the
information code alone cannot extract — project-wide (not task-focused). The guiding frame:
*self-infer first, ask deeply only where being wrong is dangerous* (business model, domain
invariants, security policy must be user-confirmed even when code-inferable; technical WHY and
conventions need only a light confirm when the code answers them).

**Existing-docs handling.** Read existing docs (reference status). Review any existing
CLAUDE.md/AGENTS.md **critically** — decide what to fold into the dryforge system, what to drop, and
what to improve — then present the review to the user, explain it, and get approval.

## Phase 3 — GENERATE (write the harness) — `references/harness-format.md`

**Force-load `references/harness-format.md`** and generate the whole harness to its spec, in order:

1. If a CLAUDE.md exists, back it up to `.dryforge/backup/`.
2. Create `docs/` and every file in it (harness-format spec).
3. Create CLAUDE.md / AGENTS.md (identical content).
4. Create a module AGENTS.md per module identified in SCAN.
5. Record the current state in `tracking/status.md` (done vs. remaining, against full scope).
6. Create the `.dryforge/` directory if absent.

Explore sources fully before writing; verify each file against the code both ways (omission /
hallucination) as you go — this self-check is separate from Phase 4.

## Phase 4 — REVIEW (verify quality) — `references/harness-review.md`

**Force-load `references/harness-review.md`** and run a self-adversarial pass against its four
dimensions: content (substantive density + quality principles), format (self-containment, altitude,
no references), completeness (required files present), and source-cross-check (omission vs.
hallucination, with future-scope content exempt). Findings: internally resolvable → fix directly;
needs user intent → carry to Phase 5 and ask.

## Phase 5 — USER GATE

Present the whole harness to the user — not a raw document dump, but a walk-through of the key
decisions captured (what SCAN/ELICIT found, what each doc records, what was dropped from old docs and
why). Resolve any Phase-4 questions that need user intent. On approval:

- Write `.dryforge/status.json` with the initialized marker — `{ "initialized": true }`. This is a
  **local-only** marker (inside the gitignored `.dryforge/`): its presence tells a later `go` that
  the harness already exists, so every change is a **delta**; its absence means first-cycle creation.
- Confirm `.dryforge/` is in `.gitignore`.

Then migration is complete. Remind the user to clear the session before running `ready`/`set` → `go`.

## Completion gate (avoid self-judgment A=A)

Done only when ALL hold:
- Every `docs/` file exists (7 core + tracking: status.md, decisions/index.md, findings.md).
- CLAUDE.md and AGENTS.md both exist, with identical content.
- An AGENTS.md exists for every identified module.
- REVIEW passes (no blocking finding under `references/harness-review.md`).
- The user has approved.
- `.dryforge/status.json` written (initialized) and `.dryforge/` is gitignored.
