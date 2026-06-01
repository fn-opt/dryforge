# output-format.md — the 3-doc contract

Defines what a **producer skill** (set or ready) outputs and
**go consumes**. This is the contract between the producer skills and go.

**Core principle:** exactly ONE part is a rigid, machine-parsed schema — the
Execution Graph. The three documents' bodies are *content requirements*: the agent
designs the structure per project (intent fixed, structure flexible). All content is
stack-agnostic — project specifics are discovered while reading the project, never hardcoded.

## The three documents (handoff governs)

### handoff — governing doc + intent injection
Must convey (structure is the agent's to design — 3 hard gates or 30):
- **Document Roles** table + conflict resolution: spec defines *behavior*; plan defines
  *order and work targets*.
- File locations (as project-root-relative paths, e.g. `.dryforge/spec.md` — never
  machine-absolute, so the 3-doc stays portable across the fresh go session) + the big
  picture (execution shape).
- **Hard gates**: non-negotiable constraints the executing agent cannot derive from code alone.
- Intent decided while authoring but not captured in spec/plan.

### spec — what to build (ground truth)
Must convey: product behavior; key design rationale (decision + why); domain
decisions/invariants; API surface; edge cases as explicit rules; required verification.
spec is ground truth — on conflict spec wins; spec errors are fixed only with user
approval.

### plan — what to do (tasks + the machine graph)
Must convey: per-task **behavioral contract** (goal, **work targets** — files |
state | external resource — and verification gate); **thinking-base** (decision +
reason where not code-derivable); shared-write guidance (prose, below); a phase
narrative for humans; and the **Execution Graph** (below). The verification gate
matches the deliverable type: a file diff for code, captured external evidence for
state/operational work. Target shape and gate are discovered from the project, not
assumed.

## The Execution Graph — the only rigid part

A fenced `yaml` block inside the plan. go parses it for scheduling:

```yaml
tasks:
  - id: T5
    depends: [T2, T3]      # task ids that must finish first
    risk: RISKY            # OPTIONAL: RISKY | MECHANICAL | NONE
regen_barriers:
  - { after: [T3], run: "<regen step — discovered while reading the project>" }
```

- `depends` is the **only encoded judgment** (which task needs which). the producer
  computes it; go follows.
- `risk: RISKY | MECHANICAL | NONE` is an **optional** per-task atom alongside `depends`.
  It sizes **only** the implementer's per-task test ceremony — it never changes whether code is
  verified or reviewed, and never touches gate topology. Derive it per task (see
  `references/dependency-calc.md`): RISKY if the behavioral contract names an explicit edge case,
  invariant, state-coordination, or validation rule; NONE if the target is config / schema / docs /
  pure scaffold with no behavioral surface; otherwise MECHANICAL. This is a derivation heuristic
  judged per task, not a fixed checklist. If a producer omits it, go falls back to the implementer
  judging risk at build time (today's behavior) — no break.
- go derives waves by topological sort of `depends`, then dispatches in
  batches of **≤8 concurrent**.
- `regen_barriers` = cross-cutting steps between waves (timing: after task X). The
  command is discovered per project while reading the code, not hardcoded.
- Do **not** encode produces / consumes / shared_write / waves here — they are prose,
  runtime-derived (git diff), or computed.
- `id`s match the prose plan; the graph is the scheduling skeleton only.

## Shared-write handling — two layers (hint + safety net)

Parallel tasks must not collide on shared/registration files (an aggregator/index file, a module
list, a routes table, …). Two layers, not a strict prediction:

1. **Hint** (prose in plan, best-effort, may be incomplete): per task, e.g. *"Do not
   write the shared registration files; a single wiring step adds all registrations at
   the end of the wave."* Proactively avoids known collisions. Not authoritative.
2. **Guarantee** (runtime, go): before merging a wave, detect changed-file
   overlaps across task branches (`git diff`). Declared-shared files are already
   deferred; an **undeclared** overlap degrades safely (serialize / ad-hoc defer /
   escalate); a git merge conflict is the final backstop. A missed hint becomes a
   *handled conflict*, never silent corruption.

## Authoring rules (for the prose bodies)
- Replace premature implementation code with **behavioral contracts** (goal,
  invariants, what-to-test — not how).
- **thinking-base**: record *decision + reason* where the executing agent could not derive
  it from code. **Never fabricate a reason** — if you would have to invent it, escalate to
  the user.
- **Stack-agnostic**: no project-specific assumption as a rule; specifics (build
  targets, regen commands, conventions) are discovered from the project.
- The three docs' section layout is the agent's to design; only the content above is
  required.

## A complete worked example

See `references/example-3doc.md` for one full `handoff` + `spec` + `plan` (an idempotent-submission
feature) — read it once to anchor the shape and altitude. It is **illustrative, not a template**:
its role names are deliberately generic because a real 3-doc is stack-agnostic and written against
the project discovered at runtime. Copy the structure, not the words.
