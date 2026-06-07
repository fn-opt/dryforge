# foundation-format.md — the Project Foundation section (handoff, first cycle only)

The format contract for the **Project Foundation** section of the handoff: the authoring form when
`ready` writes it, and the reading rules when `go` consumes it. Used **only in the first cycle** (no
harness exists yet). Shared byte-identical between `ready` and `go`.

## Purpose

The first cycle's SCOPING/DESIGN produces project-wide foundation knowledge that does *not* belong in
spec.md. spec.md carries only **this task's** execution contract; the **project-wide** foundation —
the full domain model, architecture decisions, security model, conventions, future scope — goes in
the handoff's Project Foundation. This split keeps `go` from over-implementing (it executes the
task's spec, not the whole project) while giving it project context to implement *within*.

## Structure — four fixed sections

Structure the Foundation as **four sections**. Do **not** organize it by `docs/` filename — naming
sections after harness files invites box-filling (reward-hacking) when `go` later builds the harness;
keep the Foundation about the *project*, and let `go` map it to files.

- **Section 1 — Project identity.** What, for whom, at what scale, under what constraints (the
  SCOPING result).
- **Section 2 — Domain model.** Entities, relationships, state transitions, rules, invariants, edge
  cases (the domain-design result). **Mark each entity as `[implementation target]` or
  `[project context]`** — `go` implements only the targets and uses the rest as design context. The
  thickest section.
- **Section 3 — Technical decisions.** Architecture, security model, conventions, operations (the
  technical-design result). **Only decisions the user confirmed.**
- **Section 4 — Future scope.** What is planned for the project but out of this task's scope. `go`
  does **not** implement it — it is the context for judging that the current implementation stays
  compatible with the future.

## Labeling rule — separate from the handoff's governing role

Begin the Foundation with an explicit label: *"Non-executable project context — `go` reads this
section as context + harness source, not as an implementation target."* The handoff's existing
governing parts (Document Roles, Hard Gates, conflict resolution, …) stay clearly separated from the
Foundation, so `go` never confuses a governing instruction / hard gate with project context. The
Foundation is a **conditional expansion inside the handoff's "supplement" role**, not a new authority.

## How `go` uses it (dual use)

- **At execution.** `go` reads the Foundation when it first reads the handoff → it implements the
  spec's task *with* project context. (E.g. a Foundation that records a role-based permission model
  makes `go` design the spec's "auth implementation" with role support in mind.)
- **At harness creation.** Each Foundation area maps to `docs/` files per `harness-format.md`:
  domain model → business-rules.md; technical decisions → architecture.md + security.md +
  standards.md + operations.md; identity → the CLAUDE.md overview; future scope → status.md's
  "remaining."

## Lifetime

Created in the first cycle only. After `go` creates the harness, the 3-doc (handoff included, with
its Foundation) is archived to `.dryforge/NNN/`. From the next cycle on, the harness takes over the
project-context role, so no Foundation is written.

## When absent (the `set` entry)

The Foundation is a **first-cycle `ready` artifact, not a hard requirement.** `set` (which has no
SCOPING/DESIGN dialogue) does not write one. When `go` runs a first cycle from a `set`-produced
3-doc, it finds no Foundation and **degrades gracefully** — sourcing the harness from spec + code +
handoff. The result is thinner but valid; this thinness is exactly why `set` routes
project-design-thin inputs to `ready`.

## Content quality

The §quality bar of `harness-format.md` (non-derivability, work-changing, density,
project-specificity, consequence-of-absence) applies to the Foundation too. A thick Foundation is
normal, but every sentence must carry a core fact — not padding.

## Universality guard

Stack-agnostic. The four sections hold project-specific identity, domain, decisions, and scope in the
project's own terms — no stack assumed, discovered at runtime.
