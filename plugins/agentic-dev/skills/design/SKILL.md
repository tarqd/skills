---
name: design
description: >
  Turn a design discussion into the project's bootstrap document set —
  DESIGN doc, Architecture Decision Records (ADRs), and a phased
  implementation plan — or evolve an existing one. Auto-detects whether
  the repo is fresh (bootstrap) or has prior design artifacts (evolve);
  asks the user when state is ambiguous. Use when the user explicitly
  asks to write up a design, turn a discussion into ADRs, add or
  supersede ADRs from a conversation, propose changes to an existing
  design doc, add a new phase to the plan, or scaffold ADRs and phase
  docs in a fresh repo.
user-invocable: true
disable-model-invocation: true
---

# design — turn a discussion into bootstrap docs or evolve existing ones

Produces or evolves three artifacts from a design discussion:

1. **Design doc** — what the thing is and why it exists
2. **ADRs** — the load-bearing architectural decisions
3. **Phased implementation plan** — phases with tasks and acceptance criteria

Two **targets** (the skill auto-detects which applies; asks when unsure):

- **bootstrap** — fresh repo. Write everything from scratch.
- **evolve** — existing repo. Read what's there, integrate changes via
  `adr new` / `adr supersede`, propose design-doc diffs, optionally
  add a new phase doc. **Never auto-edit existing artifacts.**

Output playbooks:

- bootstrap → [`references/bootstrap-output.md`](references/bootstrap-output.md)
- evolve → [`references/evolve-output.md`](references/evolve-output.md)

Phase 0 of a fresh plan always covers project scaffolding and agent
setup; implementation details are the coding agent's call.

---

## Step 1: Detect target (bootstrap vs evolve)

Inspect the repo for existing artifacts:

- **Design doc** — any of `DESIGN.md`, `PRODUCT.md`, `docs/DESIGN.md`,
  `docs/design.md`.
- **ADRs** — any non-`README`/`TEMPLATE` `*.md` file in `docs/adr/`,
  `docs/architecture/decisions/`, `doc/adr/`, or `adr/`.
- **Phase docs** — any `phase-*.md` file in `docs/phases/`.

Decision matrix — all 8 combinations explicit:

| Design | ADRs | Phases | Target                                              |
| ------ | ---- | ------ | --------------------------------------------------- |
| ✗      | ✗    | ✗      | **bootstrap** (no ask)                              |
| ✓      | ✓    | ✓      | **evolve** (no ask)                                 |
| ✓      | ✓    | ✗      | **evolve** (note: a new phase may need adding)      |
| ✓      | ✗    | ✗      | **hybrid** (DESIGN is authoritative; bootstrap ADRs + phases under existing constraints) |
| ✗      | ✓    | ✓      | **hybrid** (bootstrap DESIGN to match existing ADRs / phases; ask to confirm) |
| ✗      | ✓    | ✗      | **hybrid** (bootstrap DESIGN + phases; ask to confirm) |
| ✓      | ✗    | ✓      | unusual — ask                                       |
| ✗      | ✗    | ✓      | unusual — ask                                       |

When asking (always for "unusual" rows; offered as confirmation for
"ask to confirm" rows), the options via `AskUserQuestion`:

- **Treat as fresh** — overwrite anything in the way (with per-file
  confirmation before each overwrite).
- **Treat as existing (evolve)** — integrate changes; never auto-edit.
- **Hybrid** — bootstrap the missing artifacts, evolve the existing ones.

The target is fixed for the run and recorded in the summary.

---

## Step 2: Identify the conversation mode

Independent of target — applies in both bootstrap and evolve.

**Mode A — Distill existing conversation.**
The conversation already contains substantial design discussion.
Extract decisions already made, identify gaps, confirm, then generate.

**Mode B — Structured interview.**
The user wants to develop the design now. Run the interview below,
then generate.

Ask the user which they want if it's not obvious. If there's already
a long design conversation in context, default to Mode A and confirm:

> "It looks like we've already covered a lot of ground — want me to
> distill this conversation into the [bootstrap docs / proposed
> changes], or would you prefer a structured interview first?"

If Mode A surfaces 3+ Open Questions in step 3, **fall back to
Mode B for those rounds only** — don't make the user repeat the
whole interview just to fill gaps.

---

## Step 3: Extract or develop the design

### Mode A — Extracting from conversation

Read the full conversation history. Identify:

- **What is being built / changed** — for bootstrap: the core
  product/system in one sentence. For evolve: the change to the
  existing design in one sentence.
- **Key properties** — for bootstrap: the 4–6 things that make the
  design distinctive. For evolve: what properties are being added,
  removed, or walked back.
- **Load-bearing decisions** — choices where the "why not X" matters
  as much as the "what". Heuristic: if the decision could have gone
  another way and the whole system would look different, it's
  load-bearing.
- **Explicit rejections** — alternatives the user consciously ruled
  out.
- **Walked-back decisions** (evolve only) — old decisions being
  superseded. Each becomes an `adr supersede` move.
- **Phase-able work** — what has to come first, what builds on what.
  Evolve: is this a new phase, or modifications to an existing one?
- **Open questions** — discussed but not resolved.

Summarize back to the user (template varies by target — see the
output playbook for your target). Wait for confirmation before
generating.

### Mode B — Structured interview

Ask in a conversational flow, not as a numbered list. Wait for
answers before proceeding. Adapt to what they say.

**Round 1 — The thing:**

- (bootstrap) What are you building? One sentence if possible.
- (evolve) What's the change to the existing design?
- What's the core value / motivation — what does this do / change
  that the prior state doesn't?
- Who uses it and when do they reach for it?

**Round 2 — The hard decisions:**

These surface ADR-worthy choices. Ask the ones relevant.

- What persistence/storage model? What did you rule out?
- What's the concurrency/scheduling model? Why that one?
- What does the public API surface look like? What stays internal?
- What external dependencies are load-bearing? What did you
  decide not to depend on?
- What are the explicit non-goals — what won't this do?
- Where is the hardest technical risk? What are you most unsure
  about?
- (evolve only) Which existing ADRs does this walk back or narrow?
  Which stay accepted?

**Round 3 — The phases:**

- (bootstrap) What's the minimum to have a working demo? What comes
  after that? What's the natural build order?
- (evolve) Does this need a new phase, or modifications to an
  existing one? Which phase number / file?
- What should the demo show?

When you have enough, summarize and confirm.

### Worked example — load-bearing vs not

- *Load-bearing (write an ADR):* "Use snapshot persistence, not
  event sourcing." Persistence model defines the whole architecture;
  every storage/recovery/replay decision branches on this. Future
  contributors will be tempted to add an event log; the ADR is what
  tells them why we don't.
- *Not load-bearing (don't write an ADR):* "Use `flume` for the actor
  inbox channel." `flume` is interchangeable with `crossbeam_channel`
  or `tokio::sync::mpsc` — swapping it out is a 10-line PR, not an
  architectural shift. A line in the README or a code comment is
  enough.

The test: "If we revisited this decision in two years and chose the
other option, would large parts of the system have to be rewritten?"
Yes → ADR. No → code comment or PR description.

Generate **3–7 ADRs** in bootstrap mode. In evolve mode, generate
only what changed — typically 1–3 new/superseded ADRs per run.
Resist proliferation either way.

---

## Step 4: Generate the documents

Branch by target:

- **bootstrap** → follow
  [`references/bootstrap-output.md`](references/bootstrap-output.md).
- **evolve** → follow
  [`references/evolve-output.md`](references/evolve-output.md).
- **hybrid** → run bootstrap-output for missing artifacts, then
  evolve-output for existing ones. State the order at the top of
  the report so the user can scan.

For phase-shape guidance (one good arc + alternatives), see
[`references/phase-shapes.md`](references/phase-shapes.md).

---

## Step 5: Confirm and refine

After generating (bootstrap) or surfacing diffs/supersede pairs
(evolve), ask:

> "How does this look? A few things worth checking:
>
> - Are the ADRs capturing the right decisions, or did I miss any
>   load-bearing ones? Are any too trivial to be worth an ADR?
> - (evolve) Do the supersedes name the right replaced decisions?
>   Anything still Accepted that should be walked back?
> - Do the phase boundaries feel right? Too big, too small?
> - Is there anything in [Phase 0 / the new phase] that's too
>   prescriptive — something the coding agent should decide entirely?"

Revise based on feedback.

---

## What this skill produces and what comes next

**Bootstrap mode** ships the document set and the pipeline continues:

1. `/bootstrap-repo` — git/GitHub onboarding.
2. `/track-plan @docs/phases/phase-0-scaffold.md` (if Phase 0
   needs slicing) or `phase-1-<slug>.md`.
3. `/track-drive <parent-issue>` — execute one slice at a time,
   with structured carry-over / follow-up / retrospective reports.
4. `/adr` — manage ADRs over time.

**Evolve mode** produces a change set the user reviews + applies:

1. Review the proposed ADR new/supersede moves and design-doc/phase
   diffs. Apply via `/adr new` / `/adr supersede` (or accept the
   patches inline).
2. If a new phase was added: `/track-plan @docs/phases/phase-N-<slug>.md`.
3. `/track-drive <parent>` as usual.

The PostToolUse hook in this plugin fires on ADR edits and nudges
about supersedes when an Accepted ADR's body is being changed.
Trust the nudge.

## Hard rules

- **Do not auto-trigger.** Only run when explicitly requested.
- **Never invent decisions.** If the conversation or interview
  didn't cover something load-bearing, surface it as an Open
  Question in the summary rather than picking a position.
- **3–7 ADRs (bootstrap) / 1–3 (evolve).** Resist proliferation.
- **Phase 0 always exists for bootstrap** even if minimal.
  Subsequent phases describe *capabilities*, not implementation
  steps.
- **Never overwrite existing bootstrap files** without explicit
  per-file confirmation.
- **Delegate ADR scaffolding to the `adr` skill's conventions.**
  Don't duplicate ADR format here; cross-reference
  `../adr/references/new.md` / `supersede.md`.

Evolve-specific hard rules (never auto-edit existing artifacts,
change-set gate, etc.) live in
[`references/evolve-output.md`](references/evolve-output.md) — the
flow that owns them.
