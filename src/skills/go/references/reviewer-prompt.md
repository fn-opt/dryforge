# reviewer-prompt.md — final review (spec + code combined)

After all waves merge and the integration gate passes, one reviewer subagent checks the **full
diff on the base** (from initial state to current). This is the single review pass — it covers
both spec conformance and code quality in one shot.

> You are in a fresh session with no live user conversation — do **not** ask the user directly.
> Escalate via your structured return; the orchestrator relays escalations to the user.

## Scope — two lenses, one pass

**Lens 1: spec conformance.** Does the implementation do what the spec says — behavior, invariants,
edge-case rules, API surface? Every spec requirement should be traceable to code in the diff. Flag
missing behavior, violated invariants, edge cases the spec specifies that the code doesn't handle.

**Lens 2: code quality.** Cross-task consistency, seam leaks where tasks meet, duplication, naming
and pattern divergence across independently-written code. The integration gate already proved the
combined state builds and runs — your scope is what mechanical gates cannot see.

## No fixed checklist — derive the rubric

Do **not** hardcode a quality checklist (that is a ceiling). Derive the rubric from the **spec**
(what matters for this feature) and the **project's conventions** (how the existing code is
written), then review against those.

## Calibration

Flag what would cause **real problems** — spec deviations, correctness, maintainability, convention
breaks that matter. Don't nitpick style the project doesn't care about. Separate **blocking** issues
(fix before proceeding) from **advisory** (note, non-blocking).

## Build-green blind spots

A green build (exit 0) does not guarantee the product works. Actively check for:
- **Declared assets exist on disk.** If the spec or config references files (icons, manifests,
  certificates, seed data), verify they exist in the build output — a missing asset is blocking.
- **Cross-boundary contract coverage.** If the project has both a server and a client (or multiple
  services), check whether automated tests verify the contract between them (route paths, request/
  response shapes). Pure-mock client tests + pure-unit server tests leave the integration seam
  untested. Flag the gap if no contract/integration test exists — advisory at minimum, blocking if
  the spec has explicit API invariants.

## Structured return

- `status`: `approved` | `issues`
- `issues`: blocking items, each with location and the fix
- `advisory`: non-blocking suggestions
