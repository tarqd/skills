# Choosing and delegating to a model

Which Claude model to put on a task, a subagent, or a workflow stage. Focused
on the Claude 5 series. Facts here are current as of 2026-07; when a decision
turns on a capability flag, verify against the live models documentation rather
than trusting a cached table.

## The lineup

Ordered most to least capable.

| Model | ID | Context | Where it wins |
| --- | --- | --- | --- |
| Claude Fable 5 | `claude-fable-5` | 1M | The hardest, longest, most ambiguous work — multi-hour to multi-day autonomous runs, first-shot implementation of well-specified systems, dense or degraded vision, sustained parallel delegation |
| Claude Mythos 5 | `claude-mythos-5` | 1M | Identical to Fable 5; available only through Project Glasswing. Use Fable 5 unless the org participates. |
| Claude Opus 5 | `claude-opus-5` | 1M | The default for complex agentic coding — multi-file features, larger refactors, end-to-end work; high-precision code review; strong multi-agent coordination |
| Claude Sonnet 5 | `claude-sonnet-5` | 1M | Near-Opus quality on coding and agentic tasks, and faster — the workhorse for breadth and fan-out |
| Claude Haiku 4.5 | `claude-haiku-4-5` | 200K | Simple, scoped, latency-sensitive work: classification, extraction, mechanical transforms, high-volume passes |

Use the exact ID strings — they carry no date suffix. Haiku 4.5 is the only one
with a 200K window rather than 1M, which matters as soon as a subagent has to
read large files.

## Picking a default

Start at **Opus 5** for anything agentic and reach in either direction with a
reason:

- **Up to Fable 5** when the task is genuinely at or above the edge of what
  Opus 5 finishes cleanly: long-horizon autonomous runs that must hold
  instructions across hours, deeply ambiguous multi-threaded requests where the
  model has to determine next steps, first-pass implementation of a system
  that would otherwise take days of iteration. Its turns run long — many
  minutes at higher effort — so it is the wrong choice for anything
  interactive. Two constraints to check first: Fable 5 is not intended for
  offensive cybersecurity or biology and life-sciences work and will decline
  those requests, and it requires 30-day data retention (unavailable to
  zero-data-retention orgs).
- **Down to Sonnet 5** when the task is well-specified and the bottleneck is
  throughput rather than judgment. This is the right default for wide fan-out —
  many subagents doing bounded work in parallel, where the run finishes when
  the slowest one does.
- **Down to Haiku 4.5** when the work is mechanical and the answer is checkable:
  labeling, extracting fields, rewriting to a fixed shape, sweeping a list.
  Don't hand it anything requiring multi-step reasoning, and watch the 200K
  window.

The orchestrator is one context; the subagents are many. Tier decisions
therefore land hardest on the fan-out, not the loop — a weak orchestrator
directing strong subagents is usually the wrong shape.

## Delegation patterns

**Keep the main loop on one model.** Prompt caches are model-scoped, so
switching the orchestrator's model mid-session throws away the cached prefix.
When part of a task wants a different tier, delegate it to a subagent on that
model instead of switching the loop.

**Match the model to the shape of the subtask, not its importance.**

| Subagent job | Model |
| --- | --- |
| Wide read-only exploration across many files | Sonnet 5 — breadth, and it returns fast enough that a wide fan-out still converges |
| Bounded, well-specified implementation from a clear spec | Sonnet 5 |
| A hard, self-contained implementation the orchestrator can't hold in context | Opus 5 |
| Adversarial verification / independent second opinion | Opus 5 — fresh context matters more than tier, but review precision is a real strength here |
| Mechanical sweep over a known list (rename, reformat, classify) | Haiku 4.5 |
| A track of work that will run for hours without supervision | Fable 5 |

**Fresh context beats a bigger model for verification.** A verifier subagent's
value comes from not having seen the reasoning that produced the artifact.
Spending up a tier for a verifier that shares the author's context buys less
than spending down a tier for one that doesn't.

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
- Orchestration and hard implementation: Opus 5.
- Exploration and bounded implementation subagents: Sonnet 5 — these fan out
  wide and the round finishes when the slowest one does.
- The nightly migration sweep: Fable 5 — it runs unattended for hours and has
  to hold the spec across the whole run.
```

The reason is what lets someone (or the agent) revise the choice sensibly when
the workload changes.
