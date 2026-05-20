---
name: adr
description: Manage the project's Architecture Decision Records — propose new ADRs, supersede or deprecate existing ones, flip status (accept / reject), and audit the ADR set for drift. Use when the user says "write an ADR", "propose an ADR for X", "supersede ADR-N", "deprecate ADR-N", "accept ADR-N", "audit ADRs", "check the ADR set", or when a non-trivial architectural decision needs to be recorded. Detects project convention (filename pattern, header style, section template, index format) from existing ADRs before making changes — never invents a format.
user-invocable: true
disable-model-invocation: true
---

# adr — manage the project's ADR set

Five operations — propose, supersede, accept, reject, audit — over
one shared foundation: detect the project's existing convention,
then conform to it. Never invent a new format.

## Inputs

First positional arg picks the operation:

- `new <title>` — propose a new ADR. Detailed playbook:
  [`references/new.md`](references/new.md).
- `supersede <old-ref> [<new-ref>]` — supersede an existing ADR.
  Detailed playbook: [`references/supersede.md`](references/supersede.md).
- `accept <ref>` — flip a Proposed ADR to Accepted (inline below).
- `reject <ref>` — flip a Proposed ADR to Rejected (inline below).
- `audit` — audit the ADR set for drift. Detailed playbook:
  [`references/audit.md`](references/audit.md).

If the first arg is missing or ambiguous, use `AskUserQuestion` to
pick the operation. Do not guess.

## Common prework (every operation)

### 1. Locate the ADR directory

Probe in order; first match wins:

- `docs/adr/`
- `docs/architecture/decisions/`
- `doc/adr/`
- `adr/`

If none exist and the operation is `new`, ask via `AskUserQuestion`
whether to create `docs/adr/` (recommend) or use a different path.

If none exist and the operation is `supersede`, `accept`, `reject`,
or `audit`, end with "no ADRs found".

### 1a. Default convention (zero-ADR projects)

When the project has no ADRs yet, the `new` flow uses the **plugin
default**: 4-digit zero-padded filenames (`NNNN-slug.md`),
Nygard-strict sections, README index. The user can override by
editing the first ADR manually; convention detection then picks up
their choices from ADR-0002 onward. Full default + override
mechanics in [`references/conventions.md`](references/conventions.md).

### 2. Detect convention

**Don't guess. Read.** Full procedure:
[`references/conventions.md`](references/conventions.md). The short
version is the six things to extract:

1. Filename pattern (e.g. `NNNN-slug.md`, `adr-NN-slug.md`).
2. Header line shape (e.g. `# ADR-NNNN: Title` vs `# ADR-NN — Title`).
3. Section template (Nygard-strict vs. free-form bold paragraphs).
4. Index format — does `README.md` exist in the ADR dir; what does
   one entry look like.
5. Status legend (Proposed / Accepted / Deprecated / Rejected /
   Superseded — which strings the project uses).
6. Reference / cross-link style (bullet list vs. inline prose).

Cache the detected convention for the rest of the run. Do not
re-detect per step.

---

## Inline: accept / reject a Proposed ADR

Small status flips. Don't need their own reference file.

1. Resolve the ADR file from the ref (number, filename, or path).
2. Read its current status. If it isn't `Proposed`, stop and ask
   via `AskUserQuestion` — accepting an already-Accepted ADR is
   suspicious; rejecting an Accepted ADR is a supersede in
   disguise (use `supersede` instead).
3. Confirm via `AskUserQuestion`: "ADR-N (<title>) is moving from
   Proposed → Accepted/Rejected. Proceed?" Gate; do not skip.
4. Edit the ADR's `Status:` line in place. Keep the rest of the
   body untouched.
5. If a `README.md` index exists and its entries carry a status
   hint, update the matching index entry.
6. Report: file path, before/after status.

## Hard rules (every operation)

- **Read convention before writing.** Never invent a new filename
  pattern, header style, or section template. If the project has
  zero ADRs, ask the user to confirm conventions before scaffolding
  the first.
- **Never reuse a number.** Always extend; never fill numbering gaps
  (gaps are historical — rejected drafts, renumbered drafts — and
  filling them rewrites history).
- **Never silently overwrite** an existing ADR file. If a target
  path exists, stop and ask.
- **Never delete or rewrite** the body of an existing ADR. Status
  flips and Supersedes / Superseded-by lines are the only allowed
  edits to an existing ADR.
- **Two-way cross-links are mandatory** for `supersede`. If you
  cannot edit both sides, do neither.
- **Don't auto-create the ADR directory** without an
  `AskUserQuestion` confirmation.
- **Audit is report-first.** Never apply fixes during audit — gather
  findings, present them, then ask before editing.
- **One operation per run.** Don't chain "new + supersede + audit"
  in one invocation. Re-invoke for each.

## When to invoke

- A non-trivial architectural decision is being made and the
  rationale needs to outlive the PR description.
- An existing ADR is being walked back, narrowed, or replaced.
- A new agent needs to onboard onto the project and the ADR set
  should be coherent.
- CLAUDE.md cites ADRs that may have drifted (pair with
  `/check-claude-md` after `adr audit`).

## When NOT to invoke

- Trivial fixups (typo, formatting) inside a single ADR — just edit
  the file directly.
- The decision is small enough to live in a PR description or
  commit message.
- The "ADR" is really a how-to / tutorial / runbook — those belong
  in `docs/` outside the ADR directory.
