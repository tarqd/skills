# Propose a new ADR

Prework completed: directory located, convention detected. (See
[`conventions.md`](conventions.md).)

## Steps

### 1. Compute the next number

- List ADR files matching the detected pattern.
- Extract numbers, sort, take `max + 1`.
- If there's a gap in the numbering (e.g. `0001, 0002, 0004`), **do
  not** fill the gap. Gaps are historical — rejected drafts,
  renumbered drafts — and filling them rewrites history. Always
  extend.

### 2. Confirm title and slug

- Title comes from the user's args. If the title is vague ("the
  database thing"), `AskUserQuestion` to refine.
- Slug: lowercase, hyphen-separated, derived from the title. Drop
  stopwords if the slug is over ~40 chars.
- Compose target filename per the detected pattern.
- Report: `Proposed: <path>`.
- If the target path exists, stop. (Should not happen if next-number
  logic was correct, but defend against it.)

### 3. Gather body inputs

If the user didn't supply them, ask via `AskUserQuestion`:

- **Context** — one paragraph: what is the problem, what's the
  current state, what's driving the decision now.
- **Decision** — one paragraph: what is being decided.
- **Alternatives considered** — at least one alternative with a
  one-line rationale for rejection. (More is better; minimum one.)

The user may want to fill these in themselves. Honor that: write a
body with the right section headers and `TODO:` placeholders rather
than fabricating content. Never invent rationale.

### 4. Write the body

**Zero-ADR project (no convention detected):** copy from
[`template.md`](template.md). It is the canonical Nygard-strict
default and the `Status:` line is pre-set to `Proposed`. Replace
the angle-bracket placeholders with content (or leave `TODO:`
markers if the user wants to fill the body manually).

**Existing ADRs (convention detected):** follow the detected
section template **exactly**. The two common shapes:

**Nygard-strict shape:**

```
# ADR-NNNN: Title

**Status:** Proposed

## Context

<paragraph or TODO>

## Decision

<paragraph or TODO>

## Alternatives Considered

**<Alternative name>.** <one-line summary>. Rejected: <reason>.

## Consequences

**Positive:**
- <bullet or TODO>

**Negative:**
- <bullet or TODO>

## References

- <ADR cross-link, issue link, external link, or TODO>
```

**Free-form shape:**

```
# ADR-NN — Title

**Status:** Proposed.

**Decision.** <paragraph or TODO>

**Why.** <paragraph or TODO>

**Alternatives.** **<Alternative name>.** <one-line>. Rejected: <reason>.

**Out of scope.** <bullets or TODO>

**Open questions.** <bullets or TODO>

**References.**
- <link or TODO>
```

Use the **exact** header style (colon vs em-dash) and number width
detected. If the project uses a non-breaking hyphen in the header,
use it; copy the exact byte.

### 5. Update the README index (if present)

Append (or insert in the correct sorted position) an entry matching
the existing line shape. The status hint should reflect Proposed.

If the index is sorted, insert in numeric order. If the index is
in append order, append. Read the existing entries to tell which.

If no README exists, do not create one.

### 6. Report

- Path of the new ADR.
- Suggested next step:
  - If the ADR has multi-slice implementation work, recommend
    `/track-plan @<adr-path>` to slice it.
  - Otherwise: "fill in the body and open a PR".
- Reminder: ADR is `Proposed`. Re-invoke `adr accept <ref>` when
  it's ready to land as Accepted.

## Hard rules

- **Never reuse a number.** Always extend.
- **Never fabricate** Context, Decision, Alternatives, or
  Consequences content. TODOs are fine.
- **Never overwrite** an existing file.
- **Header style must match** the project's detected style
  exactly — including separator character and number width.
