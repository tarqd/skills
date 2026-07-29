# Writing agent instructions for Claude Opus 4.8

`claude-opus-4-8` — the previous-generation Opus, still widely deployed and the
standard fallback target when a newer model declines a request. Worth reading
when a project pins it, or when a CLAUDE.md has to work on both 4.8 and the 5
series.

**The headline for anyone switching between 4.8 and Opus 5: they lean opposite
ways.** Opus 4.8 under-reaches for capabilities that need an explicit decision;
Opus 5 over-reaches. An instruction file tuned for one is miscalibrated for the
other, which is a good argument for keeping model-specific guidance short,
labeled, and condition-based.

## Under-triggering — the main tuning axis

Opus 4.8 is conservative about reaching for capabilities that require a
deliberate "decide to use this" step: web search, knowledge retrieval,
file-based memory, subagent delegation, custom tools. It won't reach for
something complex or expensive unless reasonably sure it's needed. It follows
instructions well, so this is straightforwardly steerable — but you have to say
*when* each capability applies, not merely that it exists.

Two places to put that:

- **The system prompt / CLAUDE.md** — e.g. check memory before any task longer
  than a few turns and write new findings to it as you go; delegate when a task
  fans out across independent items rather than iterating serially.
- **Each tool's own description** — a prescriptive "call this when the user
  asks about current prices or recent events" gives measurable lift over a
  description that only states what the tool does. This is the higher-leverage
  of the two and is often skipped.

Search specifically is surface-dependent: with a system prompt present, search
is high-precision and low-recall — triggering slightly more often but running
fewer rounds, while knowledge-retrieval tools trigger *less* often. A
search-first instruction recovers the rate: search before answering when
current information would change the answer, and begin searching immediately on
open-ended research requests rather than asking a scoping question first.

## Narration

Opus 4.8 narrates more than Opus 4.7 — more text between tool calls, longer
end-of-task wrap-ups. Two implications:

- **Remove forced-progress scaffolding** ("after every 3 tool calls, summarize
  progress"). It does this on its own.
- **Add a silence default if a coding agent is too chatty** — default to
  silence between tool calls, write only on a finding, a direction change, or a
  blocker, one sentence each; no narrating routine actions; one or two
  sentences on the outcome at the end. In testing this restores 4.7-like
  terseness with no quality loss.

For knowledge-work deliverables, verbosity responds well to an instruction in
user preferences or the user turn — prefer exposing a verbosity preference over
hard-coding a length.

## It asks more often than you want

Opus 4.8 is deliberate. On minor decisions it would previously just make — a
variable name, a default value, which of two equivalent approaches — it tends to
pause and ask, and it often closes a finished task with "want me to also…?"
rather than doing the obvious next step or stopping cleanly. Preferred in
high-stakes or unfamiliar codebases; irritating everywhere else.

Grant autonomy on the small stuff while keeping caution where it matters: pick
a reasonable option and note it for minor choices; still ask first for scope
changes or destructive actions. In Claude Code testing this cut ask-rate by
roughly 12 percentage points with no increase in over-reach.

## Long-horizon work

Opus 4.8 is strong at long autonomous runs — complex refactors, overnight
sessions that complete without correction. To get that, **give the full task
specification up front in a single well-specified first turn and run at high
effort**. Its long-horizon coherence comes partly from reasoning more at each
step; combined with a clear up-front goal, that often produces output that is
both more efficient and more accurate than piecemeal direction.

## Effort

Start at `high` and iterate rather than reflexively reaching for `xhigh`. Sweep
`medium` / `high` / `xhigh` on your own evals and weigh the tradeoff per route —
the relationship isn't monotonic, since higher effort up front often *reduces*
turn count and total cost on agentic work, while some tasks do equally well at
`medium` in less time. Reserve `max` for extremely hard, latency-insensitive
cases. It respects effort strictly at the low end, so on moderately complex
tasks at `low` there is some risk of under-thinking.

## Writing voice

Prose is clearer, warmer, and less hedged than 4.7, with fewer measurable
tics — roughly the opposite direction from the 4.7 shift. **If a file contains
style instructions added to counter 4.7's terseness or to inject warmth,
re-evaluate them; they may now overcorrect.**

## Thinking disabled

With thinking off, Opus 4.8 occasionally writes longer explanations of its
reasoning into the visible response. The simplest fix is to leave adaptive
thinking on. If it must stay off, scope the output in the system prompt:
respond only with the final answer, no exploratory reasoning, rejected drafts,
or meta-commentary about process.

## Code review

Same caveat as the rest of the family: a review prompt saying "only report
high-severity issues" or "be conservative" is followed literally, which
depresses measured recall even though bug-finding improved. Ask for coverage
with confidence and severity attached, and filter downstream.

## Design defaults

Opus 4.8 has a persistent default house style on open-ended briefs — warm
cream/off-white backgrounds, serif display type, italic word-accents, a
terracotta/amber accent. It reads well for editorial and portfolio work and
badly for dashboards, dev tools, fintech, healthcare, or enterprise apps, and
it shows up in slide decks as well as web UIs.

Generic corrections shift it to a different fixed palette rather than producing
variety. Either specify a concrete alternative in full, or have it propose
several distinct directions before building and implement only the chosen one.
