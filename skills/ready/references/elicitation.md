# elicitation.md — Phase 2 ELICIT (the dialogue)

This phase is the heart of the front door: a real conversation that turns a natural-language
goal into a captured **intent**, from which a deep spec is written. It replaces a human
brainstorming partner — so it must *actively ask*, not silently assume.

**Floor, not ceiling.** This is dialogue guidance, not a fixed script. Use judgment about which
questions matter for *this* goal. Never hardcode questions or stack choices into the skill —
specifics are discovered at runtime from the goal and (if present) the code.

## Stance

- **Lead with a recommendation.** From the initial goal, form a reasonable, standard, YAGNI-sized
  conception *first*, present it, and let the user adjust — rather than interrogating from a blank
  slate. A concrete proposal is faster to respond to than an open question.
- **Don't ask what you can already derive.** If the goal or the existing code settles an answer,
  resolve it yourself (this is the autonomous enumeration from Phase 1) and move on. The job of
  self-interrogation is to *generate sharp questions and pre-resolve the derivable* so the
  conversation is dense, not bloated — never to *avoid asking*.

## Asymmetric depth — where to spend questions

Three tiers. Place each decision in the right one:

1. **Functional intent (the spec) → ask deeply.** What behavior, which edge cases, which
   invariants must hold, what is in/out of scope, the error/consistency stance, the preserved
   contract (for a change to existing behavior). This is what only the user holds — mine it.
2. **Load-bearing technical decisions → default, then *surface* (never silent).** Propose a
   standard default, but **state it together with its trade-off and let the user override in one
   beat** — do not bury it. A silently-defaulted load-bearing choice traps the user who doesn't
   know to object (and that user benefits most from being asked). Check fit **both ways**: the
   default may be under-powered for what they intend, or the choice they named may be heavier than
   they need (surface the overhead). One line, overridable, then proceed.
3. **Trivial decisions → silent default.** Anything whose change costs nothing downstream — just
   pick a sensible default and mention it in passing if at all.

**What counts as "load-bearing" (definition, not a checklist):** a decision whose change would
force rewriting multiple downstream tasks or invalidate the plan's structure. Whether a given
decision is load-bearing for *this* goal is judged at runtime — do **not** encode a fixed list of
"always-surface" topics (that would be a ceiling, and would smuggle in stack assumptions).

## Mandatory: surface the technical shape before SPEC

A spec cannot be written without a target technical shape, and for greenfield (0→1) there is no
existing code to derive it from (EXPLORE supplies nothing). So **before leaving ELICIT you MUST
have surfaced the load-bearing technical shape at least once** — the persistence approach, the
interface/delivery form (service / library / UI surface / CLI / …), and any other choice the whole
plan rests on. Surface = propose a concrete default *with its trade-offs* and give the user a beat
to override; never default it silently, and never skip it because the functional questions felt
more important. If EXPLORE already fixed the shape (an existing project), **confirm** it rather than
re-ask.

This is deliberately a *dimension to surface*, not a fixed topic list (stay stack-agnostic — the
concrete candidates come from the goal at runtime). Skipping it is the classic silent-default trap:
a user who did not think to state a stack gets the wrong one, discovered only at build time. Treat
an un-surfaced load-bearing technical shape as a **material gap that blocks the transition to
SPEC**.

## Delivery — use AskUserQuestion for structured choices

When a question has clear, enumerable options (stack choice, persistence approach, scope
boundaries, yes/no trade-offs), use the `AskUserQuestion` tool instead of plain text. This
gives the user a clickable selection UI instead of forcing them to type answers.

- Use `options` with 2–4 concrete choices, each with a short `description` of the trade-off.
- Put your recommended option first with `(Recommended)` in the label.
- The user can always pick "Other" to type a custom answer.
- For questions where multiple answers are valid, set `multiSelect: true`.
- Pure open-ended questions (describe your use case, what edge cases matter) stay as plain text.

## Rhythm — one question or several?

Ask the **highest-leverage questions first**; batching a few related questions in one turn is
allowed when it serves the user. Don't pad with low-value questions to seem thorough.

## Transition gate — when to stop and write the spec (mixed)

Stop eliciting and proceed to SPEC when **either**:
- the user signals "that's enough" — **but** if you judge a *material gap* still remains (a
  decision that would change the build and that the user has not addressed), say so and ask the
  remaining high-impact question rather than closing silently; **or**
- there is nothing left that the user's input could decide — then declare you are moving to write
  the documents, and proceed.

Premature closure (closing while a real intent-gap survives) is the central risk; the Phase 4
intent-incompleteness probe is the backstop (`intent-review.md`). Closing here is not final — the
probe can reopen this dialogue for a genuine intent-gap.

## Terminology (keep precise)

- **spec = the contract** (the binding WHAT; ground truth; authority).
- **plan = a provisional blueprint** that realizes the spec — not the authority.
- A task's content is written as a **behavioral contract** (intent: goal/invariant/what-to-verify),
  not premature code. Do not call the plan itself "the contract."

## Universality guard

No concrete stack, framework, library, or tool name appears in this file or in the skill. All
guidance is stack-agnostic; the actual stack is proposed and discussed at runtime from the goal
and the code.
