# Choosing and delegating to a model

Which Claude model to put on a task, a subagent, or a workflow stage. Focused
on the Claude 5 series. Facts here are current as of 2026-07; when a decision
turns on a capability flag, verify against the live models documentation rather
than trusting a cached table.

## The lineup

Ordered most to least capable.

| Model | ID | Context | Role |
| --- | --- | --- | --- |
| Claude Fable 5 | `claude-fable-5` | 1M | Long-running orchestration; design and planning; focused review of correctness-impacting code with many external invariants |
| Claude Mythos 5 | `claude-mythos-5` | 1M | Identical to Fable 5; available only through Project Glasswing. Use Fable 5 unless the org participates. |
| Claude Opus 5 | `claude-opus-5` | 1M | Implementation, and the default for everything not covered by another row |
| Claude Sonnet 5 | `claude-sonnet-5` | 1M | Bounded work with a complete brief — exploration, well-specified implementation, the wide legs of a fan-out |
| Claude Haiku 4.5 | `claude-haiku-4-5` | 200K | Mechanical work with a checkable answer: classification, extraction, fixed-shape rewrites, high-volume passes |

Use the exact ID strings — they carry no date suffix. Haiku 4.5 is the only one
with a 200K window rather than 1M, which matters as soon as a subagent has to
read large files.

## Picking a model

Decide from what the task **is**, not from a guess about what it will consume.
You cannot estimate a run's length or spend before it starts, and a rule that
asks you to is a rule you will apply badly. Match on the role instead:

**Fable 5** — three roles, all of them "hold a lot at once, for a long time":

- **Long-running orchestrator.** The agent that stays alive across a multi-hour
  or multi-day run, dispatches others, and has to still be holding the original
  instructions at the end.
- **Design and planning.** Ambiguous, multi-threaded requests where the job is
  to work out what the next steps *are* — not to execute steps already given.
- **Focused review of correctness-impacting code with many external
  invariants.** The discriminator is invariants the diff doesn't show: ordering
  guarantees, protocol contracts, concurrency assumptions, things another system
  relies on. Not "is this code good" — "is this code still correct given
  everything it has to stay true to."

Two hard constraints regardless of fit: Fable 5 is not intended for offensive
cybersecurity or biology and life-sciences work and will decline those
requests, and it requires 30-day data retention, so it is unavailable to
zero-data-retention organizations.

**Opus 5** — implementation, and the default. If the task is to build, change,
or fix something against a spec that already exists, it goes here. If none of
the other rows clearly matches, it also goes here. Prefer this over deliberating
about the choice.

**Sonnet 5** — bounded work with a complete brief: exploration, well-specified
implementation, the wide legs of a fan-out. The test is whether the subagent
could be handed the brief with no further conversation and still finish.

**Haiku 4.5** — mechanical work with a checkable answer: labeling, extracting
fields, rewriting to a fixed shape, sweeping a known list. Nothing requiring
multi-step reasoning, and watch the 200K window.

When two rows seem to apply, take the more capable one. When you are unsure at
all, take Opus 5 — an unnecessary tier up is recoverable, a task that stalls
because it was under-resourced is not.

## Delegation patterns

**Keep the main loop on one model.** Prompt caches are model-scoped, so
switching the orchestrator's model mid-session throws away the cached prefix.
When part of a task wants a different tier, delegate it to a subagent on that
model instead of switching the loop.

**Match the model to the shape of the subtask, not its importance.**

| Subagent job | Model |
| --- | --- |
| Wide read-only exploration across many files | Sonnet 5 |
| Bounded, well-specified implementation from a clear spec | Sonnet 5 |
| A hard, self-contained implementation the orchestrator can't hold in context | Opus 5 |
| Adversarial verification / independent second opinion | Opus 5 |
| Review of code whose correctness turns on invariants outside the diff | Fable 5 |
| Mechanical sweep over a known list (rename, reformat, classify) | Haiku 4.5 |
| A track of work that runs unsupervised across many turns | Fable 5 |

**Fresh context beats a bigger model for verification.** A verifier subagent's
value comes from not having seen the reasoning that produced the artifact. A
verifier one tier down that starts clean is worth more than one a tier up that
inherits the author's context — so spend the tier on the invariant-heavy
reviews above, and spend isolation everywhere else.

**Delegation propensity differs by model, and that is a prompting problem.**
Opus 5 and Fable 5 both reach for subagents readily; Opus 4.8 under-reaches.
If you are writing an agent definition or CLAUDE.md that will run on Opus 5,
expect to need a damping instruction (see `snippets.md`). If it will run on
Opus 4.8, expect the opposite. Instructions written for one are wrong for the
other, which is a good reason to keep delegation guidance short and
condition-based rather than emphatic.

## Effort

Effort is the primary control for the intelligence / latency tradeoff on the 5
series. It is a harness or API setting, not something you prompt for — `low`,
`medium`, `high` (the default), `xhigh`, `max`. Haiku 4.5 does not support it.

- **Opus 5** — start at the default and sweep. `low` and `medium` are unusually
  strong on this model and are the primary lever for latency wherever quality
  holds; step up to `xhigh` for demanding coding and agentic work. If you
  carried effort defaults over from an earlier model, re-run the sweep.
- **Sonnet 5** — keep the `high` default for most work; raise to `xhigh` for
  the hardest coding and agentic tasks. It respects effort strictly at the low
  end, so on moderately complex work at `low` there is real risk of
  under-thinking. If reasoning looks shallow, raise effort rather than
  prompting around it.
- **Fable 5** — `high` for most tasks, `xhigh` for the most capability-sensitive
  work, `medium` or `low` for routine work. Lower settings still often exceed
  prior models at their ceiling. At higher effort on routine work it can
  deliberate past what the task needs.

Two things effort does *not* do:

- It does not reliably shorten visible output on Opus 5. Verbosity is a
  prompting problem; see `snippets.md`.
- It does not substitute for a clear task specification. Every model in this
  lineup performs better given the complete spec up front in one well-formed
  turn than given the same information dribbled across several.

## Recording the choice

When a project standardizes on a model per role, put it in CLAUDE.md as a short
table with the reason attached, not as a rule:

```markdown
## Model assignment
- Implementation, and anything not listed below: Opus 5.
- Exploration and bounded implementation subagents: Sonnet 5 — they get a
  complete brief and don't come back for clarification.
- Planning a phase, and reviewing the scheduler and the wire protocol:
  Fable 5 — both turn on invariants that aren't visible in the diff.
- The nightly migration sweep: Fable 5 — it orchestrates unattended and has to
  hold the spec across the whole run.
```

The reason is what lets someone (or the agent) revise the choice sensibly when
the workload changes.
