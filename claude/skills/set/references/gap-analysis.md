# gap-analysis.md — VERIFY: the three passes

Phase 2 checks the `{spec, plan}` against the real project and against itself, then
**classifies** what it finds. VERIFY *detects* (and fixes structure immediately); RESOLVE
(`refinement-rules.md`) disposes of the rest. The passes are an ordered scaffold — the
judgment of *what counts as a gap* is yours, not a hardcoded checklist.

## Pass 1 — structure (deterministic, fix now)

Do the plan's concrete claims actually exist in the project? Paths, build targets, import
paths, dependencies, commands. Method: targeted `rg` / `find` / the project's own graph or
build queries (discovered in GATHER).

**Fix structural mismatches immediately** — correct wrong paths/targets/names to the
project's real values *before* Passes 2–3, so later passes judge a corrected document. This
is the one fix done inside VERIFY; everything else is deferred to RESOLVE.

## Pass 2 — requirements (bidirectional trace)

Trace at the requirement/task level (index level, not line-by-line):

- **Forward** (spec → plan): every spec requirement maps to ≥1 task. Unmapped = **coverage gap**.
- **Backward** (plan → spec): every task is grounded in a spec requirement. Ungrounded =
  **orphan task**.

A coverage gap or orphan can be intentional (deferred scope, a scaffolding task) or a real
miss — you often can't tell from the docs alone. Classify; don't auto-resolve.

## Pass 3 — cross-consistency

- **spec internal** — contradictions (a rule that excludes the very thing another rule needs).
- **plan internal** — task A's output ≠ task B's expected input; impossible ordering.
- **spec ↔ plan divergence** — plan does what the spec doesn't ask, or does something the spec forbids.
- **convention fit** — against the Pattern summary from GATHER: does the plan follow the
  project's established patterns?

## Two completeness probes (fold candidates into the disposition)

Beyond the three passes, two probes catch gaps the passes miss. They are deliberately
**liberal** — they raise more than survives — so every candidate they produce must clear the
**grounds gate** (`refinement-rules.md`) before it becomes a confident escalation.

- **Domain-silence probe** — does the spec stay SILENT on a standard *kind* of property this
  **deliverable's domain** implies? What that kind is depends on the domain (discovered, not assumed)
  — for a service: lifecycle/state transitions, rejection cases, consistency, idempotency; for other
  deliverables it differs (coverage/freshness/cross-references for docs, policy/least-privilege/drift
  for infra, schema/null-handling/lineage for data, …). If the spec is silent on a kind its domain
  implies, do **not** invent the rule (no fabrication) — surface the silence as a candidate.
- **Completeness sweep** — when a requirement is cross-cutting (auth, permission, row/tenant
  scoping, auditing, …), enumerate **every** site it must apply to and flag any missing site.
- **Cardinality-coupling probe** — when the plan **adds to or removes from a collection** (registry
  entries, enum members, a rule/command set, route table), scan the existing code/tests for sites
  that **hard-code the old count or the exact member set** (an assertion on the collection's length,
  a frozen name-set, a snapshot). Changing the cardinality breaks those — flag them so the plan updates them
  (or makes them count-agnostic). go's integration gate is the backstop that *catches* this, but
  surfacing it up front turns a mid-run gate failure into a planned task.

Cross-stack testing showed roughly half of what these probes raise are false positives, so they
are paired with the grounds gate: never escalate a probe candidate you cannot ground.

## Taxonomy → disposition

| Finding | Disposition |
|---|---|
| structural mismatch | **fix now** (Pass 1) |
| convention violation | auto-fix in RESOLVE (to the project pattern) |
| coverage gap / orphan task | **escalate** (intentional, or a real miss?) |
| contradiction (spec, or spec↔plan) | **escalate** — never self-resolve a spec conflict |
| missing decision (rationale needed, absent) | thinking-base in RESOLVE — record if known, else escalate |

**Escalate = ask the user.** It means *surface as a question* (actually posed in RESOLVE, with
a proposed answer) — never silently resolve, defer, or drop. A spec conflict in particular only
the user can settle: spec is ground truth, fixed only with approval.

## When a summary isn't enough

If a GATHER summary can't settle a pass (you need to see specific code), dispatch a
**narrow, focused** read then (read-only; `subagent-management.md` prompt pattern). GATHER is
the broad sweep — these are pinpoint follow-ups, kept small.
