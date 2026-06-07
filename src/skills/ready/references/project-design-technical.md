# project-design-technical.md — first-cycle DESIGN (technical decisions)

Establish the project's **technical decisions** with the user. This is the **present** mode (knowledge
lives with *you*; the user speaks in generalities — translate them into concrete options +
trade-offs, the user decides). Run after domain design; depth follows the SCOPING character.

It is the opposite of domain design. Domain *draws out* what the user knows; technical *presents*
what the user doesn't, as options the user chooses among. The user says a generality ("I want it to
be secure") → you translate it into concrete choices ("an external auth service vs. rolling your own;
the latter needs these decisions…") → the user decides → their language narrows → repeat. A few
rounds converge a generality into this project's specific technical decision.

**Floor, not ceiling.** You know how to present technical options. This file blocks the failure modes
and lays the floor; which options to present, in what order, is your judgment.

## Failure modes and guardrails

- **Silent decision (the core one).** Never settle a technical direction without user approval.
  Translate the generality into concrete options with trade-offs and let the user pick — don't quietly
  choose the default and move on.
- **Over-engineering.** When a technical choice is heavier than the SCOPING character warrants, detect
  it and surface it to the user with your reasoning. Don't shrink it unilaterally — the user decides.
- **Stack-locking.** Don't presuppose a specific technology. When presenting options, honor the
  stack-agnostic principle: offer the *kinds* of approach and their trade-offs, not a single assumed
  stack.
- **Security generalities.** Don't stop at "follow security best practices." Concretize until this
  project's own security decisions — auth approach, authorization model, audit scope — are settled by
  user confirmation. (A generality here is the same as no decision.)
- **No conventions established.** Entering `go` with no conventions lets the executor invent patterns
  arbitrarily. Establish at least the minimal project standards (code conventions, test strategy,
  module boundaries) with the user.

## What to cover (proportional to SCOPING depth)

- **Architecture** — components, how they communicate, data flow.
- **Security model** — auth approach, authorization model, audit scope (this project's own policy,
  not a generality).
- **Conventions** — code conventions, test strategy, module boundaries.
- **Operations** — deployment, environment, external dependencies.

Scale to the character: a personal tool is "adopt the default + a one-beat confirm" per area; a
larger/enterprise project is "design each area deeply." The depth comes from the character, not a
fixed amount of ceremony.

## Depth floor

- Every technical decision is **settled by user confirmation** — no solo agent decision.
- Every decision that has a trade-off was presented as **options + each trade-off**.
- The security model is this project's **specific** policy, not a generality.
- **No open technical question remains.**

The ceiling is open.

## What this produces

The confirmed technical decisions, recorded in the handoff's Project Foundation
(`foundation-format.md`, "technical decisions" section) — only decisions the user confirmed. `go`
uses them as design context while implementing, and later turns them into `architecture.md` +
`security.md` + `standards.md` + `operations.md`.

## Universality guard

Stack-agnostic. Options are presented as kinds-of-approach with trade-offs; the concrete stack is the
user's decision at runtime, never assumed or named as a rule here.
