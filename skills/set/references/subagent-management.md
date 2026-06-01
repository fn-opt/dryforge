# subagent-management.md — reading the project via subagents

The project-reading phase (set's **GATHER** / ready's **EXPLORE**) protects
main context by delegating project reading to **read-only** subagents that return **summaries
only** — raw code never enters main. Read-only parallel reads are low-risk; the worktree/commit
constraints that go needs do not apply here.

## Topology — scout first, then pattern + infra

Dispatch order encodes one dependency: **Scout runs first**; its output (where the relevant
modules are) seeds the other two, which then run **in parallel**.

| Subagent | Reads | Returns (summary only) |
|---|---|---|
| **Scout** (first) | project layout, conventions, entry points. Use `CLAUDE.md`/`AGENTS.md` as a guide if present; otherwise explore broadly and tell the user you are reading the whole project. | structure + rules/conventions + locations of modules relevant to the spec/plan |
| **Pattern** (parallel) | the modules Scout flagged: existing similar implementations — the **HOW reference**. The unit of similarity is whatever the codebase uses (a module / handler / data shape / test shape / function family — not assumed to be any particular architecture) | pattern catalog + key shapes/signatures |
| **Infrastructure** (parallel) | constraints *not visible in feature code*: infra (deployment/orchestration config, env, CI), build config, dependency manifests | infra constraints + build/lint rules + dependency state |

**These three roles are *what to cover*, not a mandated subagent count.** Scale to the project: a
small or simple codebase (or a greenfield change with little to read) may need a single read or a
merged Scout+Pattern pass — collapse the roles when over-decomposition would cost more than it
protects. The floor is "cover layout + the HOW reference + external constraints," not "always three
subagents."

The Pattern read is a HOW reference and a reality-check for the plan's claims — never the
authority for WHAT (that is the spec).

## Prompt pattern (required elements, not a fixed script)

Each dispatch prompt must pin:

- **Scope** — exactly what to read (for Pattern/Infra: the specific modules/areas Scout found).
- **Return contract** — a structured summary; **summaries only, no raw code or file dumps in
  the reply**.
- **Read-only** — do not edit anything; this is reconnaissance.
- **Compactness** — keep the summary small enough to live in main context.

Example skeleton — the four elements above are **required**; this is just *one wording* of
them. Adapt the phrasing per project:

```
Read-only recon of this project. Role: <scout layout | pattern of <modules> | infra>.
Read: <targets>. Do NOT modify anything.
Return ONLY a compact structured summary:
  - <fields for this role: e.g. layout / conventions / module locations>
If any artifact is too large to summarize, write it to a scratch file and return the path
plus a one-line digest — do not inline it.
```

## Result handling

- **Report, don't fabricate** — a summary contains only what was actually found. If the
  spec/plan points to something a subagent can't locate or confirm, it reports that as *not
  found*; it never invents structure or fills gaps with assumptions. (escalate-don't-guess,
  applied to reading — the gap then surfaces in the next phase.)
- Main keeps each subagent's **summary**, not the raw reads (sawtooth: context grows on
  dispatch, shrinks back to the summary).
- **Large results** — a subagent's reply is size-bounded. If a result would not fit, have the
  subagent write a file and return `path + one-line digest` instead of inlining.
- **Follow-up reads belong to later phases** — if a later pass needs code this sweep didn't
  cover, dispatch a *narrow, focused* read then. This phase is the broad sweep, not the only read.

## Out of scope here

- No project writes, worktrees, or commits — those are go's concern. Scratch files for oversized results are the only exception.
- What to *do* with the findings (verify, refine, elicit, compute dependencies) is the later
  phases. This file is only about turning the project into a compact, trustworthy summary without
  flooding main context.

## Universality guard

Stack-agnostic. Any concrete artifact kind named above (module / handler / data shape / test) is an
illustration of "the project's unit of similarity," never a required architecture — the actual
shapes are discovered in the project at runtime.
