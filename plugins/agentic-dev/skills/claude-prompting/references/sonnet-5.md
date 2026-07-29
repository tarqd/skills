# Writing agent instructions for Claude Sonnet 5

`claude-sonnet-5` — near-Opus quality on coding and agentic work at roughly
half the cost, which makes it the usual choice for subagents and fan-out. It
performs well on existing Sonnet 4.6 instructions; the items below are what
most often needs tuning.

## Literal instruction following

Sonnet 5 interprets instructions literally and explicitly, especially at lower
effort. It does not generalize an instruction from one item to another and does
not infer requests you didn't make. That precision is the reason it does well
on carefully tuned prompts and structured pipelines — but it means:

- **State the sweep.** "Apply this formatting to every section, not just the
  first one." An instruction you meant broadly will be applied narrowly.
- **Re-check holdover style directives.** A "be concise" line carried over from
  an earlier model now applies at face value and may overcorrect.

This is the single most important thing to know when writing a subagent
definition that runs on Sonnet 5: the brief has to be complete, because the
model will not fill gaps for you.

## Effort, and why it matters more than prompting here

Sonnet 5 respects effort levels strictly, particularly at the low end. At `low`
and `medium` it scopes work to exactly what was asked rather than going above
and beyond — good for latency and cost, with real risk of under-thinking on
moderately complex work at `low`.

If you see shallow reasoning on a complex problem, **raise effort rather than
prompting around it**. Prose instructions to think harder are a weaker lever
than the setting. If effort must stay low for latency, a targeted line —
naming the task as multi-step and asking for careful reasoning — is the
fallback, not the first move.

Rough cross-model calibration when moving work over: Sonnet 5 at `medium` is
comparable to Sonnet 4.6 at `high`, and Sonnet 5 at `high` to Sonnet 4.6 at
`max`.

## Tool use triggering

Sonnet 5 is more agentic than Sonnet 4.6 by default — it reaches for tools and
runs self-verification loops more readily. Two consequences for instruction
files:

- **With thinking disabled it is less likely to reach for tools or consider
  searching.** If a harness relies on tool calls with thinking off, add an
  explicit nudge describing when and why to call the tool.
- **Effort is also a tool-use lever.** `high` and `xhigh` show substantially
  more tool usage in agentic search and coding.

When a tool is under-used, the fix is a prescriptive description on the tool
itself — "call this when the user asks about current prices or recent events" —
not an emphatic rule in the system prompt.

## Progress updates

Sonnet 5 gives regular, well-formed interim updates through long agentic
traces. **Remove scaffolding that forces them** ("after every 3 tool calls,
summarize progress") — it now produces noise. If the shape of the updates isn't
right for your product, describe what they should look like and give an
example rather than mandating a cadence.

## Verbosity and tone

Response length calibrates to task complexity rather than sitting at a fixed
level — shorter on simple lookups, longer on open-ended analysis. If a product
depends on a particular verbosity, tune for it explicitly, and prefer a
positive example of the concision you want over a list of things not to do.

Prose style shifts between model generations. If your project relies on a
specific voice, re-evaluate the style instructions against the new baseline
rather than assuming they still land the same way.

## Design and frontend defaults

On open-ended frontend briefs Sonnet 5 settles into a consistent default visual
style. Generic corrections ("don't use that color", "make it clean and
minimal") shift it to a *different* fixed palette rather than producing
variety. Two things work:

1. **Specify a concrete alternative** — exact palette, typefaces, spacing,
   radius, motion. The model follows explicit specs precisely.
2. **Have it propose options before building** — e.g. four distinct directions
   as background hex / accent hex / typeface plus a one-line rationale, then
   implement only the chosen one. This is the reliable way to get variety
   across runs.

## Code review harnesses

A review harness tuned for an earlier model may show *lower* recall on Sonnet 5.
This is a harness effect, not a regression: when the prompt says "only report
high-severity issues" or "don't nitpick", Sonnet 5 follows it faithfully — it
investigates just as thoroughly and then declines to report findings below the
stated bar.

Ask for coverage at the finding stage, with confidence and severity attached
per finding, and filter in a separate pass. If you do want single-pass
self-filtering, define the bar concretely ("anything that could cause incorrect
behavior, a test failure, or a misleading result; omit pure style and naming
preferences") rather than with a qualitative word like "important".

## Interactive vs autonomous shape

Token usage and behavior differ between a single-turn autonomous agent and a
multi-turn interactive one. To get both performance and efficiency: run at
`high` or `xhigh`, reduce the number of required human turns, and put the task,
intent, and constraints up front in the first turn. Ambiguous prompts revealed
progressively across turns cost more and sometimes perform worse.
