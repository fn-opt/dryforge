<a id="top"></a>

<div align="center">

<img src="https://dryforge.vercel.app/assets/icon-1024.png" width="84" height="84" alt="dryforge" />

# dryforge

### You bring the what. It ships _what you meant._

Your agent works like a senior developer — an **all-in-one harness** that keeps every step honest, from project design to running code.

[Website](https://dryforge.vercel.app) · [한국어](https://github.com/fn-opt/dryforge/blob/main/README_KO.md)

</div>

**Install** — Claude Code

```
/plugin marketplace add fn-opt/dryforge
/plugin install dryforge
```

Codex

```
codex plugin marketplace add fn-opt/dryforge
codex plugin add dryforge@dryforge
```

<sub>Requires `git` and Claude Code or Codex.</sub>

---

## Not a cage. A compass.

Same model, better results. Instead of micromanaging the agent, dryforge lays down a solid basis for judgment and blocks only the ways things go off the rails — pulling the model's full power through. It sets a **floor, not a ceiling**: a better model just gets you better output.

- **Criteria, not rules.** "If X, do Y" rules cage a model. dryforge gives it a sound basis to judge for itself — rules bind, good criteria free.
- **It wakes the model's potential.** Many tools shackle the agent with procedure — "AI can't be trusted" — and end up suppressing its real skill. dryforge doesn't cap the ceiling, so the model's best comes through. The better the model, the better the result.
- **Boundaries, not control.** You approve the intent; inside that boundary the agent decides freely. That's *bounded autonomy*, not a leash.
- **"Looks done" doesn't pass.** Completion is judged by captured evidence from actually running it — checked by an independent, adversarial view whose job is to find the holes, not by the author's own feeling.
- **Verification scales with risk.** No uniform ceremony forced on every task. Risky work is verified thickly, trivial work lightly — exactly as much as it needs.
- **Ask, don't guess.** Anything not derivable from the intent is brought back to you, not decided unilaterally. One guess is worse than one pause.

---

## A project that has a system

dryforge doesn't just leave code behind. It records your project's structure, rules, decisions — and the **reasons** behind them — as real documents, building a system that lasts. That living document set is the **project harness**.

```
your-project/
├── CLAUDE.md                  # entry point for Claude Code — identity + work rules
├── AGENTS.md                  # entry point for Codex — identical content
├── docs/
│   ├── architecture.md        # composition: components, flow, dependencies
│   ├── business-rules.md      # domain logic: entities, invariants, edge cases
│   ├── security.md            # policy: protected assets, access, audit
│   ├── standards.md           # the rules: hard gates, conventions, boundaries
│   ├── engineering-notes.md   # hard-won knowledge: traps, mechanisms, checklists
│   ├── operations.md          # how to run it: setup, build, deploy
│   ├── contracts.md           # external interface contracts
│   └── tracking/
│       ├── status.md          # where the project stands vs. its full scope
│       ├── decisions/         # decision records — what was chosen, and why
│       └── findings.md        # known unresolved problems
└── <module>/AGENTS.md         # per-module scope, boundaries, invariants
```

- **Context survives sessions.** A new conversation reads the harness first and continues knowing the whole project — no re-explaining from zero.
- **The "why" is kept, not just the "what."** Decisions are recorded with their rationale, so intent doesn't quietly get reversed and the same debate doesn't repeat.
- **It stays in sync with the code.** The harness is updated as you work and reconciled against reality — documents never rot into fiction.
- **It works without dryforge.** The harness is standard `CLAUDE.md` / `AGENTS.md` files. Any agent reads it and stays grounded. You're not locked in.

---

## Same prompt, different code

Ask for the same thing in two sessions and you get two different answers — not because the model is weak, because it's *strong*. With nothing to anchor to, a capable model re-reasons everything from scratch, and the smarter it is, the wider it roams. (You think differently today than yesterday, too.)

And it's not about style — it's the *decisions* that quietly disagree:

<table>
<tr>
<td><sub>session 1 — money as integer cents</sub>

```js
const price = 1099   // $10.99
total += price       // always exact
```
</td>
<td><sub>session 2 — money as floating dollars</sub>

```js
const price = 10.99
total += price       // 0.1 + 0.2 = 0.30000000000000004
```
</td>
</tr>
</table>

One module rounds one way, the next rounds another, and the books stop balancing. Multiply that across auth, IDs, error handling — the codebase quietly fights itself.

The fix is simple: hand the strong model the **same context, every time** — the decisions already made, and *why*. That's the harness. That's dryforge.

---

## `/ready` — half an idea is enough

Most tools assume you already know *exactly* what to build. **`/ready`** assumes the opposite. Bring a one-line hunch, a bloated spec another tool spat out, scattered notes — any of it, or all at once — and `/ready` takes it as *material* and does what a senior developer does: it **asks back**. It draws out the decisions you never pinned down — even the ones you didn't know you were making — until nothing's left ambiguous. What comes out isn't transcribed requirements; it's the design you *actually meant*, ready to build.

One front door. It takes whatever you bring — and turns it into exactly what you meant.

---

## However you start, `go` finishes

Two ways in — and `/go` finishes both.

```
  /ready <INPUT>  ──▶  /go!      ──▶  working software + the project harness

  # <INPUT> — a file, a line, anything: drop it in and it figures the rest out


  Already have running code?
  /migration  grafts dryforge onto it  ──▶  your project finally has a system
              (one-time on-ramp; afterwards /ready → /go)
```

| | Command | What it does |
|---|---|---|
| **An idea, notes — any input** | `/dryforge:ready` | Any input becomes a complete, executable design — read as *material*, questioned until nothing's ambiguous, with a stack recommended if you have none. |
| **→ leads into** | `/dryforge:go` | Builds from the plan with zero waste: many tasks at once in a pre-computed order, the risky parts verified more thoroughly. → working software **+** the project harness. |
| **Code that already runs** | `/dryforge:migration` | Audits your code — surfacing real problems and undocumented intent — as it grafts the harness on. One-time; then `/ready` → `/go`. |

---

## License

MIT

<div align="center"><sub><a href="#top">↑ back to top</a> · ready / go</sub></div>
