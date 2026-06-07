# first-cycle-review.md — first-cycle REVIEW (is this a sufficient project foundation?)

In the first cycle, REVIEW runs the usual intent-incompleteness probe (`intent-review.md`) **and**
this pass. This one asks a different question: *is the spec + Project Foundation deep enough to be the
foundation of the whole project?* Same adversarial stance as intent-review — find the holes, don't
bless the work. Loaded only in the first cycle.

**Floor, not ceiling.** The failure modes and floor below are the floor; how hard you press each is
risk-proportional judgment.

## Failure modes to hunt

- **Domain too shallow** — entity *names* present, but rules / invariants / edge-case dispositions
  missing. A concept without its four facts (what it is / does / cannot do / how it ends) is a name,
  not a model.
- **Domain too narrow** — a core feature/entity is missing — the trace of closing without asking the
  user "are there others?" (the breadth guard was skipped).
- **Technical decision left open** — a "decide later" / "TBD" survives in the spec. An open
  load-bearing technical question is a gap (the executor will fill it arbitrarily).
- **Security generality** — "security considered" with no project-specific policy (auth approach,
  authorization model, audit scope).
- **Scoping mismatch** — the design is heavier or lighter than the project's confirmed character.
- **Vague modifiers remain** — "appropriately," "if needed," "as suitable" still in the spec.

## Floor

- Every domain concept meets `project-design-domain.md`'s depth floor.
- Every technical decision is closed by user confirmation (no open question).
- **Zero** vague modifiers.
- Design depth is consistent with the SCOPING character profile.

## On a miss — reopen DESIGN, don't self-fill

A finding here is one of two kinds (as in intent-review):
- **Internally resolvable** (a vague modifier you can concretize from what's already on the record, an
  altitude slip) → fix it.
- **A gap only the user can fill** (a missing domain rule, an unsettled technical decision, a
  security policy) → **do not auto-fill it.** Reopen the matching DESIGN phase (domain or technical)
  and ask the user. Auto-filling a foundation gap bakes a guess into the whole project.

## Gate

Proceed past REVIEW only when no blocking foundation gap remains — every finding either fixed or
answered by the user. State which findings were fixed and which were reopened to the user.

## Universality guard

Stack-agnostic. The probe checks depth, breadth, and decision-closure — never conformance to a stack.
What counts as a domain rule or a technical decision is whatever this project is, judged at runtime.
