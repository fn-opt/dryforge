# set-elicit.md — ELICIT (deepen the thin areas)

Activated when VERIFY's content-depth probe (`gap-analysis.md`, Pass 4) judges one or more categories
**insufficient**. Deepen those areas through dialogue with the user. set is not a format-only
converter — a thin input formatted correctly yields a thin 3-doc (and a thin harness). The questions
here are the point. If the probe judged every category **sufficient**, skip this phase entirely.

**Floor, not ceiling.** The floors below are the target; which questions reach them is your judgment.
Don't script the dialogue, and respect the probe — only deepen what it flagged.

## Pick the mode by knowledge asymmetry

For each thin area, choose the mode (per the knowledge-asymmetry principle):
- **Thin in domain** → **extract.** The rule/behavior lives with the user; draw it out (never invent
  it). Reach the domain floor: every rule verifiable (a test case derivable from it), each "must"
  paired with its "must not," edges concretely disposed, no vague modifier.
- **Thin in technical** → **present.** Translate the generality into concrete options + trade-offs and
  let the user decide. Reach the technical floor: every decision closed by user confirmation, each
  trade-off surfaced, the security model project-specific (not a generality), no open question.

(These floors mirror the first-cycle design floors — the standard is the same whether reached through
ready's design system or set's targeted deepening.)

## Failure modes and guardrails

- **Format-only pass.** Structure correct but content is one line. If the depth floor isn't met, it
  does not pass — deepen it.
- **Over-digging.** Don't re-interrogate an area the probe judged **sufficient**. Respect the probe's
  result; spend questions only on the flagged areas.
- **Giving up in Cold mode.** Even with no live conversation (files only), find the ambiguous parts in
  the files and ask the user about them. **Cold means "the files are the whole input," not "don't
  ask."** Don't attribute intent to an unseen conversation — but do ask.
- **Missing the ready-redirect point.** Detect this condition: the probe result is **first cycle (no
  harness) + no code + many categories insufficient**, all at once. In that state, set does **not**
  attempt to deepen — it tells the user to switch to ready: *"This input is too thin a foundation to
  refine with set. Use `/dryforge:ready` to design the project."* set-elicit works only when there is
  code to ground against, or when the insufficient categories are few. (An input this thin should
  start as "here's a rough doc, design it with me" in ready, not as refinement in set.)

## Depth bar

ELICIT is done when every category the probe flagged **insufficient** has been concretized to the
matching floor above (domain or technical). Categories already judged sufficient are left untouched.

## Universality guard

Stack-agnostic. The thin areas, their rules, and their technical options are whatever this project
and these docs are — discovered at runtime; no stack assumed.
