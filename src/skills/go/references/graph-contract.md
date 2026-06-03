# graph-contract.md — the Execution Graph, from go's side (parse contract)

go does **not** compute dependencies — a producer (ready or set) already did, against the whole
project. go's job is to *parse* the graph faithfully and schedule from it. This file is the
schema go reads against, so the parser has an authoritative reference instead of re-deriving the
shape from memory. The producers' authoring view is in their own `output-format.md` /
`dependency-calc.md` (in the producer's references, not go's); this is the same contract, stated
for the consumer.

## The graph — the only machine-parsed part of the 3-doc

A single fenced `yaml` block inside the plain plan. Everything else in the 3-doc is prose for
human/agent reading; this block is the scheduling skeleton:

```yaml
tasks:
  - id: T5
    depends: [T2, T3]      # task ids that must finish before T5 can start
    risk: RISKY            # OPTIONAL: RISKY | MECHANICAL | NONE — sizes the implementer's test ceremony only
regen_barriers:
  - { after: [T3], run: "<regen step — discovered by the producer while reading the project>" }
```

- **`tasks[].id`** — matches the task ids used in the prose plan. The graph is the skeleton only;
  the behavioral contract for each id lives in the prose.
- **`tasks[].depends`** — the task ids that must finish first. This is the **only encoded
  judgment**. go follows it and never re-judges, adds, drops, or reorders an edge.
- **`tasks[].risk`** *(OPTIONAL)* — `RISKY | MECHANICAL | NONE`. go reads it and passes the tier
  to the implementer of that task. It sizes **only the per-task test ceremony** — never gate
  topology, never whether code is verified or reviewed. If a producer omits it, go falls back to
  the implementer judging risk at build time (today's behavior) — no break.
- **`regen_barriers[]`** — `{ after: [ids], run: "<cmd>" }`: a cross-cutting step that must run
  **between** waves once `after` is satisfied (schema→client/type generation, contract→codegen,
  catalog rebuilds, …). The command is project-specific (discovered by the producer); go runs it
  as given, it does not invent one.

## What is NOT in the graph (do not look for it here)

`produces` / `consumes` / `shared_write` / `waves` are deliberately absent:
- **waves** are *derived by go*, not encoded — topological sort of `depends`, then split into
  batches of **≤8 concurrent** (practical parallelism ~5–8).
- **produces/consumes** were the producer's *reasoning* to derive `depends`; they don't survive
  into the graph.
- **shared_write** is a prose hint in the plan, backed by go's runtime overlap detection — not a
  graph field. (See orchestration.md "deferred wiring".)

## Rules go must hold when reading the graph

- **Follow it; never re-judge.** Derive waves purely from `depends`. Do not second-guess the
  producer's edges with your own read of the code.
- **Validate, then trust.** Before scheduling, confirm the graph **parses**, is **acyclic**, and
  every `depends` / `after` id **names a real task**. A parse failure, a cycle, or a dangling id is
  a **producer-side defect → stop and escalate**, never silently patch it.
- **The plan body and the graph must agree** on the set of task ids. A task in the prose with no
  graph entry (or vice-versa) is a defect → escalate.
