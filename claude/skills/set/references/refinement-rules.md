# refinement-rules.md — RESOLVE: convert, base, escalate

Phase 3 disposes of what VERIFY classified: **auto-fix** what is safe, **record thinking-base**
where a downstream agent couldn't derive a decision, and **escalate** the rest. Two rules run
through all of it: serve the spec, and **never fabricate**.

> **Stack-agnostic.** The conversion principles below apply to any stack; the specifics (what the
> code/queries/schema actually are) come from GATHER. Read every example category as illustrative,
> never as a rule tied to one language or tool.

## Auto-fix (non-structural)

Structural mismatches were already fixed in VERIFY. Here, fix without asking:

- **premature code → behavioral contract** (table below)
- **convention violations** → the project's established pattern (from GATHER)
- **simple spec ↔ plan mismatches** → wording, cross-references, naming

## premature code → behavioral contract

| In the plan | Do |
|---|---|
| implementation code blocks (source, queries, schema/DSL, …) | **delete** — the agent writes these after reading the project |
| feature scope, invariants, API surface, design intent | **keep** — things independent judgment could get wrong |
| non-obvious shapes (wire format, a specific predicate, a data structure) | **keep as a code/data block** — not derivable, must be pinned |

Conversion direction: *"write this code"* → *"implement this behavior: for input X produce
output Y; hold this invariant."*

The keep/cut line: **cut what reading the project reveals; keep what independent judgment
could get wrong versus the designer's intent.**

## thinking-base (decision + reason)

Record a reason only where a fresh agent, reading the project code, could **not** reach the
designer's decision on its own. Test in order:

1. Derivable from code? → **Yes**: no reason needed.
2. Unsure if it's derivable? → include it (gray-zone default: an over-included reason is
   cheap; a missing one derails the executing agent).
3. Not derivable (a reason is needed) → is it **actually on the record** — stated in the spec/plan,
   or (S1-live mode) decided in the live conversation you can see?
   - **Yes** → record *decision + reason*.
   - **No — you'd have to invent it** → **do NOT write a reason. Ask the user** — this becomes
     one of the Escalate questions below (with a proposed answer). A fabricated reason is worse
     than none: it sends the executing agent confidently the wrong way. (In **cold mode** there is no live drafting conversation to recall,
     so the docs are the *only* record of intent: "stated in the docs" is the *only* source that
     counts — never attribute a reason to a conversation that isn't in front of you. Which mode you
     are in is detected per `set/SKILL.md`'s detection rule.)

Frequent categories (accelerators for spotting candidates, **not** an exhaustive list):
trade-off / external constraint / scope boundary / convention exception / domain invariant /
non-functional (a chosen quality attribute: security posture, consistency level, perf budget) /
rejected alternative (an option the designer considered and discarded — record it, and why, so a
downstream agent doesn't "improve" the design back into the rejected choice).

## Already-grounded input (verify & promote, don't churn)

When the `{spec, plan}` is already well-grounded — e.g. authored by someone who read the code, or
otherwise carefully written — VERIFY may find ~0 structural/coverage gaps and there is little to
auto-fix. **Do not manufacture refinement to look busy.** In this mode the primary value shifts:

- **Promote hedges to verified facts.** Where the input records an *assumption* ("assuming the API
  returns X"), cross-check it against the project code and, if confirmed, restate it as a verified
  fact (or, if it conflicts, escalate). An assumption the code settles should not survive into the
  3-doc as a hedge.
- Confirm rather than rewrite; reserve questions for what the code genuinely cannot settle.

This is a mode, not a separate phase — the same VERIFY/RESOLVE machinery, recognizing that a clean
input needs *verification + promotion*, not heavy conversion.

## Finalizing the spec — append/annotate, do not rewrite

GENERATE "finalizes" the spec, but the spec is ground truth: **finalizing means appending and
annotating** (the approved auto-fixes, thinking-base, verification status, required-verification),
**not rewriting its intent.** A suspected spec *error* is never silently edited — propose it and
fix only with user approval (escalate-don't-guess). Preserve the designer's wording and intent.

## Escalate (unresolved only)

Ask the user only what you couldn't safely auto-fix: domain/scope/trade-off decisions,
suspected spec errors (spec is ground truth — propose, never edit without approval), and any
thinking-base reason you would otherwise have to invent.

- Briefly report what you auto-handled ("N items handled"), then ask only the unresolved.
- Order by priority: **blocking > data-integrity > missing-feature > optimization.**
- Attach a proposed answer to each question (the user may be non-expert).

### Grounds gate — escalate only what you can ground

A candidate gap (especially one raised by the two probes in `gap-analysis.md`) becomes a
**confident question** only if you can state ALL THREE, per site:

1. **the specific site** — the exact spec requirement / code path / endpoint (not "X in general");
2. **why it is not already covered** — a *positive* argument that the spec, the plan, or a
   framework/convention default does not handle it. "Might be missing" / "unclear" is **not
   enough** — actively rule out that it is already covered;
3. **the concrete consequence** if it is left unaddressed.

If you cannot ground all three, do **not** raise it as a confident gap. **Asymmetric default:
insufficient grounds → not a confident escalation** (drop it, or list it in the low-confidence
tier below). This is the inverse of a keep-by-default pass — escalate only what you can ground.

### Two tiers (so the gate never silently buries a real gap)

- **Confident gaps** — grounded on all three above. These are the questions you actually ask
  (ordered by priority, each with a proposed answer).
- **Low-confidence candidates** — failed the "why not covered" test (typically a pre-existing
  trait, a framework default, or something derivable from a pattern) but might still matter.
  List them briefly for a quick scan; do not press them as blocking.

Why this shape: the grounds requirement removes the bulk of probe false positives while keeping
grounded structural/contract gaps; the low-confidence tier recovers the rare real-but-hard-to-
ground item the gate would otherwise drop.
