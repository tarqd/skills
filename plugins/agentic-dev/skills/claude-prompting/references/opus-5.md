# Writing agent instructions for Claude Opus 5

`claude-opus-5` — the default for complex agentic coding and enterprise work.
Existing Opus 4.8 instruction files carry over well; the items below are the
behaviors that most often need tuning, and the ones where a file written for an
earlier model now does damage.

## Delete before you add

Three categories of instruction should come *out* of a CLAUDE.md, skill, or
agent definition that will run on Opus 5:

**Verification instructions.** "Include a final verification step for any
non-trivial task", "use a subagent to verify", "double-check your answer",
"re-verify before responding". Opus 5 verifies its own work without being told;
these compound with that behavior and produce over-verification — more tokens
and latency, no quality gain. The same goes for harness scaffolding that adds a
separate verification stage. Remove them rather than softening them.

**Thoroughness prompting.** Instructions written to make an earlier model
explore more now produce exploration past the point of usefulness.

**Depth prompting.** "Think step by step", "reason carefully before answering."
Thinking is on by default; depth is controlled by effort, not by prose.

## Verbosity

Opus 5's user-facing responses run longer than prior Opus models'. **Lowering
effort will not reliably shorten them** — effort governs how much the model
thinks, not how much it says. Prompt for length explicitly.

A short conciseness instruction is effective; in a long system prompt, pair it
with a brief reminder near the end. See `snippets.md` → *Conciseness*.

Separately, files Opus 5 writes to disk — reports, Markdown docs, summaries —
run long. If your project has the agent authoring documents, add explicit
length calibration for deliverables; it is a different instruction from
conversational conciseness and one does not cover the other.

## Narration during agentic work

Opus 5 narrates readily: it announces what it is about to do, and per-message
output during a long task is longer than prior models'. This is tunable in both
directions, and the lever is the same — describe the cadence and shape you
want, with positive examples. Instructions about what *not* to say work less
well than a sample of the style you want.

See `snippets.md` → *Communication style*.

## Scope

Opus 5 can expand a task — adding steps that weren't requested, or applying its
own judgment about what the task should be. For narrow work, constrain it
explicitly. The instruction that tests well combines four things: deliver at the
scope intended, make routine calls yourself, say so in a sentence if the request
seems mistaken but continue as asked, and finish the whole task rather than
reporting completion early. See `snippets.md` → *Scope discipline*.

## Subagents

Opus 5 delegates more readily than prior models. Delegation pays off on
genuinely independent, sizeable tracks and multiplies cost and time everywhere
else. If the harness supports subagents, give explicit guidance on which
scenarios warrant delegation, or set a deterministic cap on spawn count. See
`snippets.md` → *Subagent damping*.

Note this inverts the Opus 4.8 guidance — if you are migrating a file that
*encouraged* delegation, that encouragement should come out.

## Self-correction narration

Opus 5 catches its own mistakes well, and narrates the corrections more than
prior models do. In a user-facing product that reads as thrash. Scope
correction narration to errors that actually change the user's outcome, and
note that a follow-up question is not by itself evidence of an error — without
that clause the model will re-audit work that was correct. See `snippets.md` →
*Corrections*.

## Running with thinking disabled

Thinking is on by default on Opus 5 and can only be disabled at effort `high`
or below. If a harness disables it, two artifacts can appear:

- A tool call written into the visible text instead of emitted as a structured
  call. The turn completes normally and the call never runs — no error — and in
  an agentic loop the leaked text stays in history and skews later turns.
- Internal XML tags (`<thinking>` and others) in the visible response.

The primary mitigation for both is to leave thinking on and control cost with a
lower effort level instead; thinking enabled at `low` generally outperforms
thinking disabled at similar cost. If it must stay off, one combined
instruction covers both: allow a brief sentence before a tool call, allow the
model to say when no tool fits, and forbid internal or system XML tags
generically. **Do not name thinking tags specifically** — instructions that call
them out by name are less effective than the general form, and any rule telling
the model not to think or not to reason *increases* leakage.

## Capabilities worth knowing when you write instructions

- **Code review** — high precision and recall, and accuracy holds at lower
  effort. If a review prompt says "only report high-severity issues" or "be
  conservative", Opus 5 follows it literally and reports less. Ask for coverage
  with confidence and severity attached, and filter in a separate pass.
- **Vision** — strong on charts, documents, diagrams, and UI replication.
  Giving it crop/analyze/verify tools is a more cost-effective lever than
  raising thinking. Re-validate prompt-side vision workarounds written for
  earlier models; several are now counterproductive.
- **Long context** — 1M tokens as both default and maximum, with instruction
  following and tool calling holding across the window.
- **Multi-agent** — coordinates teams of subagents well, with effective
  writer-verifier patterns and few cases of agents overwriting each other.
- **Effort** — `low` and `medium` produce strong quality at a fraction of the
  tokens; treat them as the primary cost lever and step up to `xhigh` for
  demanding work. Re-run an effort sweep rather than carrying defaults over.
