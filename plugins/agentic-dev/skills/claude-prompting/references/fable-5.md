# Writing agent instructions for Claude Fable 5

`claude-fable-5` — the most capable widely released model, for the hardest,
longest-running, most ambiguous work. Everything here applies equally to
`claude-mythos-5`, which is the same model available through Project
Glasswing.

Two constraints to check before writing anything for it: Fable 5 is not
intended for offensive cybersecurity or biology and life-sciences work and will
decline requests in those domains, and it requires 30-day data retention, so it
is unavailable to zero-data-retention organizations.

## Refactor prescriptive instructions

**This is the most important item.** Skills, CLAUDE.md files, and agent
definitions written for prior models are often too prescriptive for Fable 5 and
measurably degrade output quality. Step-by-step recipes for tasks the model can
plan itself get in the way of planning that would have been better.

When migrating an instruction file: state the goal and the constraints, delete
the procedure, and A/B the result. Fable 5 also updates skills on the fly based
on what it learns during a task — leave room for that rather than pinning every
step.

Related: **do not instruct it to reproduce, echo, or explain its internal
reasoning in the response.** Prompts, skills, or harness instructions that ask
for this can trigger the `reasoning_extraction` refusal category. If the
application needs reasoning visibility, read the structured thinking blocks.

## Short instructions beat enumerated ones

Instruction-following is strong enough that a brief principle covers what used
to take a list. Un-steered — especially at higher effort — Fable 5 elaborates
past what the task needs: surveying options it won't pursue, explaining root
causes at length, over-structured PR descriptions, comments narrating the next
line. A short brevity instruction handles all of it; naming each pattern
individually is not more effective and is more likely to conflict internally.

The same applies to checkpoint behavior. Rather than enumerating every case
where the agent should stop, one instruction — pause only for destructive or
irreversible actions, real scope changes, or input only the user can provide —
covers it. See `snippets.md` → *Checkpoints*.

## Plan for long turns

Individual requests on hard tasks can run for many minutes at higher effort;
autonomous runs extend for hours. This is the largest structural shift teams hit
when adopting Fable 5. It is mostly a harness concern — timeouts, streaming,
progress indicators, checking on runs asynchronously rather than blocking — but
it has a prompting side: on ambiguous tasks it can overplan. See
`snippets.md` → *Act when you have enough*.

## Ground progress claims

On long autonomous runs, instruct it to audit each progress claim against an
actual tool result from the session. In Anthropic's testing this nearly
eliminated fabricated status reports even on tasks designed to elicit them.
This is the highest-value single instruction for unattended work. See
`snippets.md` → *Grounding progress*.

## State the boundaries

Fable 5 can occasionally take unrequested adjacent actions — drafting an email
nobody asked for, creating defensive git branches. Define explicitly what it
should and should not do, especially the distinction between "the user is
describing a problem" and "the user asked for a fix", and the requirement that
evidence support a specific state-changing command before running it. See
`snippets.md` → *Boundaries*.

## Delegate, asynchronously

Fable 5 dispatches parallel subagents more readily and more dependably than
prior models, and reliably manages ongoing communication with long-running
subagents and peer agents. The guidance here is the opposite of the damping you
write for Opus 5: use subagents frequently, say when delegation is appropriate,
and prefer asynchronous communication over blocking until each returns.
Long-lived subagents that keep context across subtasks save time and cost
through cache reads and avoid bottlenecking on the slowest one.

## Give it a memory surface

Fable 5 performs particularly well when it can record lessons from previous
runs and reference them later. A Markdown file is enough. Tell it where the
notes live, that it should consult them in future sessions, and what format to
use — one lesson per file, a one-line summary at the top, corrections and
confirmed approaches alike with the reason attached, no duplicates of what the
repo or history already records, and delete notes that turn out to be wrong.

To bootstrap from existing history, ask it to review past sessions with
subagents, identify themes and lessons, and write them into that location.

## Effort

`high` is the default for most tasks, `xhigh` for the most
capability-sensitive work, `medium` or `low` for routine work — lower settings
on Fable 5 still often exceed prior models at their ceiling. Reduce effort if a
task completes correctly but takes longer than necessary, or when you want a
quicker interactive working style.

At higher effort on routine work it can gather context and deliberate beyond
what the task needs, and can tidy or refactor beyond the ask. If that shows up,
add a scope instruction (see `snippets.md` → *No unrequested cleanup*) before
reaching for a lower effort setting — the higher setting is also what buys the
verification behavior and rigor.

## Rare failure modes worth a line in the file

- **Early stopping.** Deep into a long session it can occasionally end a turn
  with a statement of intent ("I'll now run X") without issuing the tool call,
  or ask permission it doesn't need. Interactively, "continue" recovers it. For
  autonomous pipelines, add the *Autonomous operation* block from
  `snippets.md`.
- **Context-budget concern.** In very long sessions it can suggest a new
  session, offer to hand off, or trim its own work — most often when the
  harness shows it a remaining-token countdown. Avoid surfacing explicit
  context-budget counts; if the harness must, add a one-line reassurance that
  ample context remains and the work should continue.

## Readability at the end of a long run

In extended agentic conversations Fable 5 can produce final text that is hard
to follow: arrow-chain shorthand, deep implementation detail, references to
thinking the user never saw. If the user reads the agent's output directly, add
a communication-style block that separates working shorthand (fine between tool
calls) from the final summary (written for someone who saw none of it). See
`snippets.md` → *Communication style*.

If the harness supports it, a `send_to_user`-style tool is the complement:
tool inputs are never summarized, so a message routed through it arrives
verbatim mid-run without ending the turn. Defining the tool is not enough —
without an instruction telling it when to call it, Fable 5 rarely does.

## Give the reason, not only the request

Fable 5 performs better when it understands the intent behind a request:
context lets it connect the task to relevant information rather than inferring
intent. In an instruction file this means saying what the project is for and
who consumes its output, not just what the conventions are — the same
explain-why principle that governs everything else, with a higher payoff here.
