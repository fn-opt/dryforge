<a id="top"></a>

<div align="center">

<img src="https://dryforge.vercel.app/assets/icon-1024.png" width="84" height="84" alt="dryforge" />

# dryforge

### An all-in-one plugin harness for Claude Code and Codex.

<h2>Your agent works like a <strong>senior developer.</strong></h2>

<p><strong>One workflow that turns intent into verified changes and carries project knowledge forward.</strong></p>

<p>
  <a href="https://dryforge.vercel.app"><img alt="Website" src="https://img.shields.io/badge/website-dryforge.vercel.app-111111?style=flat-square"></a>
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-supported-6f4ad2?style=flat-square">
  <img alt="Codex" src="https://img.shields.io/badge/Codex-supported-0f172a?style=flat-square">
  <img alt="License MIT" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
</p>

<p>
  <a href="#install">Install</a> ·
  <a href="#command-loop">Command Loop</a> ·
  <a href="#intent-realization">Intent Realization</a> ·
  <a href="#durable-project-memory">Project Harness</a> ·
  <a href="#existing-project-onboarding">Migration</a> ·
  <a href="./README_ko.md">한국어</a>
</p>

</div>

## Install and Update

Claude Code

```text
/plugin marketplace add fn-opt/dryforge
/plugin install dryforge
```

Codex

```text
codex plugin marketplace add fn-opt/dryforge
codex plugin add dryforge@dryforge
```

Auto update

Codex checks for new releases at the start of each new session and applies them automatically.

Claude Code updates automatically only when auto-update is enabled for dryforge in `/plugins -> installed -> dryforge -> auto-update`. Otherwise, update manually:

```text
# Claude Code
/plugin marketplace update dryforge
/plugin update dryforge@dryforge

# Codex
codex plugin marketplace upgrade dryforge
```

## Bounded Autonomy Architecture

dryforge redesigns the whole agent workflow around one principle: **bounded autonomy**. The model gets enough authority to think, plan, parallelize, and execute, but not enough authority to decide what the user meant.

Most agent tooling fails in one of two ways. A bare model is too loose: it can lock onto the wrong interpretation of the user's words and satisfy that instead of the user's real intent. A prescriptive harness is too tight: it can make the model optimize for the wrapper, checklist, or guardrail instead of the work.

dryforge takes the third path: **floor, not ceiling**. It fixes the minimum structure the model must respect — validated intent, authority hierarchy, execution graph, evidence floor, durable project memory — and leaves the reasoning space open inside that structure. As models get stronger, dryforge does not need to micromanage more; it needs the floor to stay calibrated.

That floor is enforced at the points where agents usually drift. `ready` makes the decision surface explicit before the spec exists, so a load-bearing unknown cannot slip through as a reasonable default. `go` follows the approved dependency graph instead of re-planning the work. Verification requires captured evidence, not self-report. Reviews and gates stay silent insurance, not the objective the model is trained to satisfy.

The floor is calibrated, not inflated. A thin input raises the elicitation bar instead of lowering output quality. Domain choices are extracted from the user; technical choices are presented with trade-offs; harmless tuning values are left to implementation. Execution is right-sized the same way: low-risk work can stay direct, risky or parallel work gets isolation, but every path keeps the same evidence floor.

| Failure pressure | dryforge counter-pressure |
|---|---|
| The model guesses what the user meant | `ready` separates understood intent from plausible-but-ungrounded defaults before writing the spec |
| The harness becomes the thing to satisfy | instructions define authority boundaries instead of over-prescribing conclusions |
| The model takes the easy checklist path | completeness and conformance are owned upstream; review is insurance |
| Parallel work drifts apart | the plan encodes dependencies once, then `go` executes that graph |
| "Looks good" replaces proof | verification is tied to captured commands, diffs, runtime smoke, or explicit evidence |

The authority split is explicit. The **user owns intent**. The **spec owns behavior**. The **plan owns scheduling**. **Evidence owns verification**. The **project harness owns durable knowledge**.

```text
conventional loop: prompt -> implementation -> correction -> lost context

dryforge loop:     elicited intent -> executable contract -> evidence-backed execution -> durable project state
```

The result is not a smaller model in a bigger cage. It is a capable model operating with the right floor: enough structure to prevent reward-hacking and laziness, enough freedom to use its reasoning.

## Failure Model

Coding agents are already strong enough to build. The failure is not raw capability. The failure is the shape of the work.

A bare agent starts from an underspecified prompt. It fills missing decisions with plausible defaults, implements those defaults as if they were yours, validates from its own point of view, and leaves the rationale in a transcript that dies with the session.

The next session has code, but code only shows outcomes. It does not show why a trade-off was chosen, which edge case was intentionally rejected, or whether an auth check is the complete policy.

dryforge addresses that failure before code exists, during execution, and after the run. It extracts the real intent, freezes it into an executable contract, runs against that contract with bounded autonomy, verifies with captured evidence, and writes the durable project knowledge where future agents start.

The result is higher quality and better token economics. Wrong-direction builds are caught earlier. Correction loops shrink. Project context is not re-explained every run.

## One Agent Workflow

dryforge replaces the stack people usually assemble around coding agents: planning modes, deep-interview prompts, ad-hoc project harnesses, AGENTS conventions, memory files, review checklists, and parallel runners.

| Usual stack | dryforge capability |
|---|---|
| planning prompt | **`ready` implicit-decision discovery** |
| deep-interview workflow | **intent-first elicitation** |
| spec generator | **executable contract** |
| parallel runner | **dependency-aware `go` execution** |
| restrictive guardrails | **bounded autonomy that keeps reasoning on-task** |
| project memory file | **committed project harness plus local contract archive** |
| hand-written agent instructions | generated `CLAUDE.md`, `AGENTS.md`, and module `AGENTS.md` |
| migration notes | **existing-project migration** |

The important part is that these capabilities are not separate pieces stitched together. They share one philosophy and one workflow. dryforge gives the agent the operating conditions required to use its reasoning well.

## Command Loop

```text
/ready <INPUT>  ->  /go  ->  working software + the project harness

Already have running code?
/migration brings the project into the dryforge harness first.
```

| Command | Consumes | Boundary | Produces |
|---|---|---|---|
| `/dryforge:ready` | an idea, spec, plan, notes, mixed input, or nothing yet | user intent becomes authority only after elicitation and approval | executable contract |
| `/dryforge:go` | the approved contract | execution is autonomous only inside the approved spec | verified implementation, harness updates, and archived contract |
| `/dryforge:migration` | an existing codebase | code-derived assumptions are confirmed where false belief is expensive | first project harness, then future work uses `ready -> go` |

Short aliases are available as `/ready`, `/go`, and `/migration`.

## Intent Realization

`ready` is the front door and the part that makes dryforge fundamentally different from ordinary planning tools.

Most planning tools organize what the user already knew how to say. Deep-interview prompts ask better questions, but still tend to work from a question list, a brainstorming pattern, or the visible content of the input.

`ready` goes after what the goal implies but never states.

Every input enters as material, not ground truth. A one-line idea, a requirements document, a model-generated plan, a design note, or scattered notes are useful, challengeable, and not authoritative until the user's intent has been validated.

The core mechanism is **decision surface accounting**: an internal pass that enumerates the load-bearing decisions the design must answer. Entities, actors, state, relationships, lifecycles, edge cases, technical shape, and hidden policy preferences are treated as decisions to close, not blanks to fill with plausible defaults.

Silent defaulting is not a terminal state.

That is the difference between understanding and guessing. If the user's stated goals and constraints already ground a decision, `ready` realizes it without asking again. If they are silent, `ready` does not pick a reasonable default and move on. Domain decisions go back to the user. Technical decisions come with concrete options, trade-offs, and a recommendation.

`ready`'s advantage is not question volume. It enumerates more internally, then asks only what survives derivation. The user sees fewer low-value questions and more questions that would otherwise become expensive wrong assumptions.

A thin input raises the bar. It does not justify a thin output. When the prompt gives fewer signals, `ready` has less to derive and more responsibility to surface the missing decisions before code exists.

The output is not a prettier plan. It is an executable contract that represents what the user meant.

## Executable Contract Layer

`ready` writes three plain files under `.dryforge`.

| Document | Role |
|---|---|
| `spec` | the **authority on what to build**: behavior, invariants, edge cases, API surface, and required verification |
| `plan` | the **implementation blueprint**: behavioral task contracts and the machine-readable execution graph |
| `handoff` | the **governing document**: document roles, execution boundaries, execution shape, and non-derivable intent |

The contract combines flexible prose with a rigid scheduling core. The prose captures intent and constraints. The execution graph is machine-parsed, so `go` can schedule work without re-guessing dependencies.

The authority hierarchy is explicit. Spec beats plan. Spec beats existing code. If the spec appears wrong, the agent does not quietly patch it. It comes back to the user.

On a first cycle, `handoff` also carries the project-wide foundation that seeds the first harness. Later cycles use the harness as project context and keep the contract focused on the current change.

Decisions that a future agent could not re-derive from code carry their reason in the contract. That is what lets execution continue without the original conversation.

## Spec-Bound Execution

`go` consumes the approved contract and owns execution from that point. The agent is autonomous inside the spec boundary, not autonomous over the user's intent.

The plan's dependency graph is the scheduling truth. `go` validates it before expensive work starts, orders work from the graph, and runs independent work in parallel only after direction is fixed. Parallelism downstream of approved intent is useful. Parallel guessing is not.

Risk controls scale verification depth. A mechanical rename and a stateful edge-case implementation do not deserve the same process. Low-risk sequential work can be handled directly. Risky or parallel work gets isolated worktrees, independent implementers, merge controls, and stronger verification. The optimization removes overhead, not the evidence requirement.

Self-report does not count. A task is not done because an implementer says it is done. `go` checks commits, diffs, declared targets, command output, exit codes, and runtime smoke where the spec requires live behavior. A verification command that dies before asserting anything is a failure, not an inferred pass.

When `go` is blocked, it does not invent the missing answer. It escalates with context. Bounded autonomy means the agent can move fast inside the approved boundary, and must stop at the boundary.

Existing projects are protected. `go` works from the right branch, refuses dirty or unsafe base state, and leaves final integration under user control.

After verification and final user approval, `go` updates the project harness and archives the active contract under `.dryforge/NNN/`, so the next cycle starts from the harness rather than a stale root contract.

## Reward-Hack Resistance

This is one of dryforge's core design choices, not a review add-on.

The harness should not become the agent's objective. If instructions are too narrow, the model learns to satisfy the wrapper instead of the user. If instructions are too loose, the model guesses the user intent and optimizes for the guess. dryforge keeps the model powerful, but makes the authority boundary explicit.

`ready` owns intent before the contract exists. The decision surface must be closed before the spec is written, so the model is not rewarded for confidently building the wrong interpretation.

`go` follows the same rule during execution. It can move fast inside the approved spec, but it cannot replace the spec with a convenient reading of the task or a checklist-shaped shortcut.

The goal is not more guardrails. The goal is a harness that pulls the model's reasoning into the work instead of training it to work around the harness.

## Durable Project Memory

After execution, dryforge writes or updates the project harness: the durable documentation layer every future agent reads first. A completed project also has a local `.dryforge/` workspace for cycle archives and the initialization marker.

Project-facing harness:

```text
your-project/
├── CLAUDE.md
├── AGENTS.md
├── docs/
│   ├── architecture.md
│   ├── business-rules.md
│   ├── security.md
│   ├── standards.md
│   ├── engineering-notes.md
│   ├── operations.md
│   ├── contracts.md
│   └── tracking/
│       ├── status.md
│       ├── decisions/
│       └── findings.md
└── <module>/AGENTS.md
```

Local dryforge workspace:

```text
your-project/.dryforge/
├── 001/
│   ├── handoff.md
│   ├── spec.md
│   └── plan.md
└── status.json
```

The harness is committed project knowledge at the entry paths Claude Code and Codex already read. It is shared by the project instead of trapped in one session, one host, or one agent's private memory.

The harness records what code cannot carry well: intent, domain rules, security policy, operating procedures, traps, decisions, and the reasons behind them.

`.dryforge/` is the local cycle workspace and archive. It holds completed contract snapshots and the local initialization marker; the committed harness is the project-facing layer.

The harness is also portable. The generated project docs do not require dryforge to be useful. If dryforge is removed later, the project keeps the asset: standard entry files, plain Markdown, and project-specific knowledge future agents can still use.

## Existing-Project Onboarding

dryforge is built for existing codebases as well as greenfield work.

Existing projects already have code, conventions, old README files, hand-written AGENTS instructions, stale plans, and tacit owner knowledge. `migration` reads the codebase, treats existing docs as reference material, and separates what code proves from what only the owner can confirm.

Code can show what an authorization check does. It cannot prove that the check is the entire policy. Code can show a state field. It cannot prove which transitions are forbidden by the business. `migration` asks where a false inference would break the project.

The output is the same project harness. After `migration`, future work enters the normal `ready -> go` loop. It is the on-ramp for projects shaped by other tools, prompt packs, manual memory files, or undocumented team habits.

## Quality and Cost Model

dryforge is efficient because it removes duplicated work, not because it does shallow work.

A bare agent often pays the same cost repeatedly: infer the project, guess missing intent, implement the guess, get corrected, rewrite, then lose the rationale when the session ends. The next session pays again with fewer clues.

dryforge pays the clarification cost once, turns the result into an executable contract, runs against that contract, and stores reusable project knowledge in the harness.

That improves both quality and cost. Fewer wrong-direction builds means fewer rewrites. Fewer repeated explanations means fewer context tokens. Fewer boundaries between planning, execution, review, and memory means fewer summaries for another tool to reinterpret.

The point is not to make the agent cheaper by doing less. The point is to stop paying for the same discovery, the same correction, and the same context reconstruction over and over.

## Usage Notes

dryforge runs only when invoked. It is best for features, project setup, migrations, and work where wrong assumptions are expensive. Tiny mechanical edits usually do not need the full loop.

Claude Code and Codex builds come from one platform-neutral source. User-facing output follows the user's language, and stack details are discovered from the project at runtime.

## Requirement

**git is required.**

## License

MIT

<div align="center"><sub><a href="#top">back to top</a> · ready / go / migration</sub></div>
