---
name: claude-prompting
description: How to write the instructions Claude reads as an agent — CLAUDE.md, AGENTS.md, SKILL.md files, subagent definitions, slash commands, hook messages, and system prompts. Use this whenever you are writing, editing, reviewing, or debugging an instruction file an agent will read; when the user asks why Claude ignores or over-applies an instruction, is too verbose, over-verifies, expands scope, or spawns too many subagents; or when deciding which model to hand a task to. Covers the over-prompting trap, instructions that used to help and now backfire, and per-model behavior deltas across the Claude 5 series.
---

# Writing instructions Claude reads as an agent

CLAUDE.md is not documentation. It is a system prompt that gets prepended to
every single turn, competing for attention with the task the user actually
asked about. Everything in it is paid for on every request, forever, whether or
not it is relevant. That framing drives most of what follows: the goal is not
completeness, it is the smallest set of instructions that changes behavior.

Applies equally to `AGENTS.md`, `SKILL.md` bodies, subagent definitions,
slash-command prompts, hook messages, and output styles. Where the guidance
differs by artifact, it says so.

## Start by reading, not writing

Before editing an existing instruction file, read it end to end and ask of each
line: *would the model do this anyway?* Modern Claude models arrive with strong
defaults — they verify their own work, narrate progress, parse JSON correctly,
and prefer real fixes over test-passing hacks. An instruction that restates a
default is not neutral; it compounds with the behavior the model already has
and pushes it into excess. The single highest-value edit to most CLAUDE.md
files is a delete.

If the file was written for an older model, assume some of it is now actively
harmful. See [Instructions that have gone stale](#instructions-that-have-gone-stale).

## Explain why, not just what

This is the technique with the widest payoff. Claude generalizes from a reason
in a way it cannot generalize from a rule, so one explained constraint covers
cases you never enumerated.

Weak: `NEVER use ellipses.`

Strong: `Your response is read aloud by a text-to-speech engine, so avoid
ellipses — it has no pronunciation for them.`

The second version also handles em-dashes-as-pauses, emoji, and ASCII tables,
none of which you had to mention. In a CLAUDE.md this usually means naming the
constraint behind a convention: *"we pin dependencies exactly because the build
is reproduced in an air-gapped CI runner"* beats *"always pin dependencies."*

When you find yourself writing a rule you cannot justify in a clause, that is a
signal the rule may not be needed.

## Say what to do, not what to avoid

Positive descriptions of the target behavior outperform prohibitions, and
positive *examples* outperform both. "Do not be verbose" gives the model a
direction but no destination; a two-line sample of the tone you want gives it
something to match.

- Instead of `Don't use markdown in responses` → `Write responses as flowing
  prose paragraphs.`
- Instead of `Don't spawn unnecessary subagents` → `Delegate when a task fans
  out across independent items; work directly otherwise.`

The same applies to formatting: the style of your instruction file leaks into
the output. A CLAUDE.md that is entirely nested bullets tends to produce
bulleted answers. If you want prose, write prose.

## State scope explicitly

Current models follow instructions literally and do not silently generalize one
to a neighbor. That precision is the point — it makes carefully tuned files
behave predictably — but it means an instruction you *meant* broadly will be
applied narrowly.

Write `Apply this to every module under src/, not just the entry point` rather
than trusting the model to infer the sweep. Likewise, an instruction placed
under a `## Testing` heading will be read as scoped to testing; if it governs
everything, hoist it.

## Structure for retrieval, not for reading

The file is scanned by a model mid-task, not read front-to-back by a human.

- **Group by concern, and tag the group.** XML-ish tags (`<code_style>`,
  `<pr_conventions>`) bind a block of instructions to a name the model can hold
  onto, which matters more as the file grows. Markdown headings work; tags are
  stronger when a block must not bleed into its neighbors.
- **Put long, stable content first.** Long-context behavior favors instructions
  and queries *after* bulk material, so background and reference material go
  above the directives that act on them.
- **Push detail into files the model loads on demand.** A CLAUDE.md that says
  "for the release process see `docs/release.md`" costs a line per turn; one
  that inlines the release process costs the whole thing per turn. Reserve the
  always-loaded budget for what changes behavior on most tasks.
- **Give 3–5 examples where format matters**, varied enough that the model
  doesn't latch onto an accidental pattern, and wrapped so they are visibly
  examples rather than instructions.
- **Put instructions at the level they apply to.** A convention that governs
  one subtree belongs in a CLAUDE.md inside that subtree, where it loads when
  the agent works there and costs nothing otherwise. Personal working
  preferences belong in the user-level file, not in a repo everyone shares.
  Root CLAUDE.md is for what is true of the whole project.

## Calibrate intensity — the over-prompting trap

Prompts written to overcome older models' reluctance now overshoot. `CRITICAL:
You MUST use the search tool` produces a model that searches when it shouldn't.
`If in doubt, use [tool]` produces a model that is always in doubt.

Rewrite escalation as description: `CRITICAL: You MUST use X when...` →
`Use X when...`. All-caps MUST/NEVER is a yellow flag — not forbidden, but each
one should be load-bearing, reserved for things that are genuinely destructive
or irreversible. A file where every rule shouts has no way to mark the rules
that matter.

If a behavior is over-triggering, the fix is almost always to dial *down* the
language, not to add a counter-rule. Two competing emphatic instructions
produce worse results than one calm one.

## Instructions that have gone stale

Audit for these specifically. Each was reasonable advice for earlier models and
now costs tokens, latency, or quality:

| Pattern | Why it backfires now |
| --- | --- |
| "Include a final verification step" / "double-check your answer" / "use a subagent to verify" | Claude Opus 5 verifies its own work unprompted; these compound into over-verification with no quality gain. **Delete rather than soften.** |
| "After every N tool calls, summarize progress" | Current models give good interim updates by default; forced scaffolding produces noise. |
| "If in doubt, use [tool]" / "Default to using [tool]" | Reliable over-triggering. Replace with a condition: "Use [tool] when it would improve your understanding of the problem." |
| "Think step by step before answering" | Thinking is on by default on the 5 series and is steered by effort, not by prose. |
| "Explain your reasoning" / "show your thinking" in the response | On Fable 5 and Mythos 5 this can trip the `reasoning_extraction` refusal category. Read structured thinking blocks instead. |
| Enumerated behavior lists (every verbosity tic, every checkpoint case) | Instruction-following is strong enough that one short principle covers what a 12-item list used to. Long enumerations are also more likely to conflict with each other. |
| Prescriptive step-by-step recipes for tasks the model can plan | Over-prescription measurably *reduces* output quality on the strongest models. State the goal and constraints; let it plan. |

The general rule: instructions written to compensate for a weakness the model
no longer has are now instructions to overdo something it already does well.

## What actually belongs in CLAUDE.md

Things the model cannot discover from the repo, or would discover expensively:

- Commands that aren't obvious from config files (the real test invocation, the
  lint gate, how to run one test).
- Conventions with a reason attached (why this error type, why this layout).
- Boundaries — what is destructive here, what needs a human, what is
  generated and must not be hand-edited.
- Pointers to the deeper docs, so detail loads on demand.

Things that do not:

- Restated defaults ("write clean code", "handle errors").
- Anything discoverable in five seconds from `package.json` / `Cargo.toml`.
- Architecture prose that belongs in `docs/` and changes rarely.
- Aspirational rules nobody follows — the model will follow them, and you will
  be surprised.

## Per-model behavior

CLAUDE.md is read by whichever model is running, so prefer instructions that
hold across models and keep model-specific tuning small and labeled. When a
user is seeing a specific misbehavior, read the file for the model they are on:

- [`references/opus-5.md`](references/opus-5.md) — verbosity, agentic
  narration, over-verification, scope expansion, subagent damping,
  self-correction narration.
- [`references/sonnet-5.md`](references/sonnet-5.md) — effort calibration,
  tool-use triggering, literal instruction following, design defaults.
- [`references/fable-5.md`](references/fable-5.md) — long-horizon runs, memory
  systems, progress grounding, checkpoint behavior, the reasoning-extraction
  refusal, skills that are too prescriptive.
- [`references/opus-4-8.md`](references/opus-4-8.md) — still widely deployed and
  the standard fallback target; under-triggers where the 5 series over-triggers.

## Choosing and delegating to a model

Read [`references/model-selection.md`](references/model-selection.md) when
deciding which model to assign to a task, subagent, or workflow stage — it
covers the 5-series lineup, relative strengths, context windows, effort levels,
and what to delegate where. Consult it whenever you are writing a subagent
definition with a `model:` field, or the user asks "which model should I use
for X".

## Reusable blocks

[`references/snippets.md`](references/snippets.md) holds tested prompt text for
the behaviors people most often need to tune: conciseness, scope discipline,
subagent damping, autonomy and checkpoints, grounding progress claims, and
communication style at the end of a long run. Prefer adapting one of these to
writing new text from scratch — they are calibrated, and reinventing them tends
to reintroduce the over-prompting patterns above.

## Reviewing an existing file

When asked to audit or improve a CLAUDE.md, work in this order:

1. **Delete first.** Restated defaults, stale instructions from the table
   above, anything the repo already makes obvious.
2. **De-escalate.** Strip caps and MUST from anything not destructive.
3. **Add reasons.** Every surviving rule that lacks a *why* gets one, or gets
   cut.
4. **Fix scope.** Anything meant broadly but written narrowly, or vice versa.
5. **Move detail out.** Long procedures become linked files.
6. **Check for conflicts.** Two instructions pulling opposite ways is the most
   common cause of "Claude ignores my CLAUDE.md."
7. **Report the diff in terms of behavior** — what will change about how the
   agent acts, not how many lines you removed.

Then say what you did not change and why, so the user can push back on
judgment calls rather than re-reading the whole file.

## Debugging "Claude won't follow my instructions"

Map the symptom to a cause before editing:

| Symptom | Usual cause |
| --- | --- |
| Instruction ignored | Buried under a heading that scopes it away, or contradicted elsewhere in the file. Check for conflicts before adding emphasis. |
| Instruction over-applied | Emphatic language (CRITICAL/ALWAYS), or a rule with no stated condition. Add the condition; remove the caps. |
| Applied to one case, not the sweep | Literal reading. State the scope. |
| Too verbose | Prompt for it explicitly — on Opus 5, lowering effort will not reliably shorten visible output. |
| Over-verifying, over-exploring | A verification or thoroughness instruction that should be deleted. |
| Wrong output format | Match your prompt's own style to the target style, and show an example rather than describing one. |

Adding more instructions is the last resort, not the first. Most fixes are a
deletion or a de-escalation.
