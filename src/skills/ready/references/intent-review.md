# intent-review.md — Phase 4 REVIEW (intent-incompleteness probe @ spec)

Before any plan is built, the frozen spec is probed for **what the dialogue missed**. The final
judge of "did we elicit enough?" is an agent, and agents (like people) cannot enumerate their own
unknown unknowns — so self-assessment ("am I done?") is the weak move. Replace it with an
*adversarial* probe: an independent reader whose job is to **find the holes**, not to bless the
work. This is the same independent-review mechanism that earns the producer its depth, pointed
specifically at intent-completeness.

This runs at **spec freeze, before PLAN** — so a wrong spec is caught before plan work is wasted —
and it is **autonomous** (it does not add a human round; the human round is the single gate at the
end, after the 3-doc).

## Risk-proportional aim (G1) — do not blanket-audit

Auditing the whole spec inflates cost for little gain. Aim the probe where the risk lives:

- **Probe the assumptions and the non-derivable decisions** — the items Phase 1 tagged as
  *assumption* or *decision+reason* (things the code/goal did not settle). Code-derived,
  already-grounded content is low risk — skip it.
- **Check the load-bearing technical shape was surfaced.** For a greenfield spec (or any spec the
  code did not pin), confirm the persistence approach, interface/delivery form, and any plan-
  defining technical choice were actually surfaced and settled. An un-surfaced technical shape is an
  intent-gap (USER) — reopen ELICIT. (Functional completeness is easy to over-focus on while the
  whole stack goes unstated; this is the guard against that.)
- **Probe the output / interface contract for completeness.** Where the spec defines an output,
  API, schema, or data model, the *shape downstream consumers (and the executor) depend on* is a
  recurring source of late-caught gaps: the entities/fields and their constraints, the exact
  response/output keys, the status/enum value sets (and whether two conceptually distinct fields
  were collapsed into one), uniqueness/identity rules. A half-pinned contract derails downstream
  work even when the behavior reads clear — so check the contract is fully specified, not just the
  behavior. Whether a given spec even *has* such a contract is judged at runtime (a pure-CLI tool's
  output format, a service's response schema, a library's return type — or nothing). Not a fixed
  field checklist.
- **Scale depth to stakes.** A small, low-blast-radius goal gets one quick pass; a complex,
  high-blast-radius goal gets several diverse lenses (e.g. implementer lens: *what can't I build
  from this?*; user-intent lens: *what did they likely mean that's unstated?*; edge lens: *what
  breaks?*). No fixed number of passes — judgment, not a checklist.

The probe is a *re-aim of the review you already run*, not an extra stacked phase. Cost stays
roughly flat; quality rises.

## Split the findings (G2)

Each finding is one of two kinds — handle them differently:

- **Internally resolvable** (a placeholder, a contradiction, an ambiguity the code or spec itself
  settles) → **fix it in the spec** autonomously.
- **A user-only intent-gap** (a decision only the user can make — the code cannot settle it) →
  **do not auto-fix it**; that would bake a guess (violating escalate-don't-guess). **Reopen ELICIT
  and ask the user** the specific question. This is the exception path; the normal path still shows
  the user just once, at the final gate.

## Degrade mode (when subagents cannot nest)

The probe is best run as a **separate reviewer subagent** (fresh eyes, has not seen the authoring
reasoning — that independence is what makes it work). In an environment where nested subagent
dispatch is unavailable, **degrade** to a *deliberately-separate self-adversarial pass*: do a
deliberate **author→skeptic role toggle** — set aside the author role you just held, then re-read
the spec as a skeptic whose only job is to find holes. Run the *same explicit lenses* the subagent
path uses, applied inline: implementer lens (*what can't I build from this?*), user-intent lens
(*what did they likely mean that's unstated?*), edge lens (*what breaks?*). Aim them with the same
risk-proportional weighting — a small goal gets one quick skeptical pass, a high-blast-radius goal
gets the lenses applied with more force and diversity. These lenses are a *floor* to provoke the
toggle, not a fixed checklist; let what is actually at risk in this spec decide where to press.
Both modes satisfy the gate; state which one ran.

## Gate

Proceed to PLAN only when the probe returns **no blocking intent-gap** — i.e., every finding is
either fixed in the spec (internally resolvable) or answered by the user (intent-gap reopened and
resolved). A residual, unanswered intent-gap blocks; escalate it rather than guessing.

## Universality guard

No concrete stack, framework, library, or tool name appears here. The probe's lenses and criteria
are stack-agnostic; what is actually at risk is judged at runtime from the spec and the code.
