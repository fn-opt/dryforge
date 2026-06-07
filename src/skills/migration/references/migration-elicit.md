# migration-elicit.md — Phase 2 ELICIT (project-wide extraction)

Collect what the code cannot reveal — across the **whole project**, not a single task. This is
independent of `ready`'s `elicitation.md`: that one is task-focused; this is project-wide, with its
own question scope, strategy, and completion bar. The only thing shared is the asymmetric-depth
principle (extract domain, present technical).

**Floor, not ceiling.** This is not a script. The guardrails and the depth floor below are the
floor; how you run the conversation is yours. Never hardcode questions or stack choices.

## The core frame — self-infer first, ask deeply only where being wrong is dangerous

You have just read the code (SCAN). Use it. Don't ask what the code already answers; do confirm what
would be catastrophic if your inference is wrong. Four cases:

| Inferable from code? | Wrong is dangerous? | Action |
|---|---|---|
| yes | no | infer, brief confirm ("is this right?") at most |
| yes | **yes** | present your inference, **confirm deeply** (domain rules, invariants) |
| no | **yes** | **ask deeply** (business model, policy decisions, security policy) |
| no | no | apply a default, skip the confirm |

The load-bearing rule: **"areas where a false belief breaks the whole project" — the business model,
domain invariants, security policy — must be user-confirmed even when the code lets you infer them.**
Code can show *what* the auth check does but not *whether it is the whole policy*; it shows a state
field but not *which transitions are forbidden by the business*. Technical WHY and conventions, by
contrast, need only a light confirm when the code answers them.

## SCAN → ELICIT — each discovered element generates a question

Walk the SCAN map and turn each finding into a question:

- **A discovered entity/module** → "what is its domain purpose, and what rules govern it?"
- **A discovered pattern** → "is this an intentional convention, or incidental?"
- **Discovered security code** → "is this the whole policy, or only part of it?"
- **A discovered architecture** → "why this structure? what did it rule out?"
- **A discovered gap** (something a domain like this usually has, absent here) → "is the absence
  intentional, or just not-yet-implemented?"

This is how breadth is guaranteed: the map drives the questions, so no major area goes unasked.

## Translate code into the user's language (the user may be non-technical)

The user may not know developer terms. Don't ask "is this an invariant?" — ask "if this changes,
must something else change too?" Don't ask "what's the authorization model?" — ask "who is allowed
to do this, and who must be blocked?" Translate the code context into the user's language, and
translate their plain-language answer back into the precise rule.

## Existing-docs handling

Existing docs are **reference material**, not authority — they may be stale. Read them, then review
any existing CLAUDE.md/AGENTS.md **critically**: decide what to fold into the dryforge system, what
to drop (already covered by the new `docs/`, or wrong), and what to improve and re-state. Present
that review to the user — what goes where, what is dropped and why — and get approval before
generating.

## Don't fabricate

Extract domain knowledge; never invent it. If the user can't answer and the code can't settle it,
record it as an open question for the user — a fabricated domain rule sends every later agent
confidently wrong.

## Completion bar (floor)

ELICIT is done only when:
- **Every module/component from SCAN has its domain purpose confirmed** — not inferred, confirmed.
- **The business model and the policy decisions are settled by user confirmation, not inference.**
- **No "I don't understand why this is here" remains in a dangerous area** (business logic, domain
  invariants, security).
- **For every identified piece of business logic, you have explicitly asked "are there rules not
  visible in the code?"** — the code shows what is implemented; this question triggers what is
  missing from it. (Code shows the *implemented* rules; the unimplemented-but-intended ones live only
  with the user.)

The ceiling is open — how to lead the conversation is your judgment.

## Universality guard

Stack-agnostic. Every example above is an illustration of a *kind* of question, never tied to a
stack. What an entity, a convention, or a security policy looks like is whatever the project is,
discovered at runtime.
