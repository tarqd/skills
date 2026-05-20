# Audit the ADR set

Mechanical + semantic integrity check on the project's ADRs.
Reports findings as **Blockers / Drift / Gaps**. Same report shape
as `/check-claude-md`.

**Do not edit files inline as you discover findings.** Gather
everything, present the report, then ask the user before applying
fixes.

Prework completed: directory located, convention detected. (See
[`conventions.md`](conventions.md).)

## Steps

### 1. Inventory

- List every ADR file matching the detected filename pattern.
- For each, read the first ~40 lines: capture number, title,
  status, any `Supersedes` / `Superseded by` lines, References
  block.
- If a `README.md` index exists, capture every index entry: number,
  title link, summary, status hint if present.

### 2. Mechanical checks

For each ADR file:

- **Numbering.** Every number from 1 (or 0) to N appears at most
  once. Duplicates → Blocker.
- **Header shape.** Matches detected style (number width,
  separator character). Mismatch → Blocker.
- **Status line.** Exists; value is in the project's status legend.
  Missing → Blocker. Unknown value → Drift.
- **Filename ↔ header agreement.** The number in the filename
  matches the number in the H1. Mismatch → Blocker.

For the README index (if present):

- Every ADR file has an index entry. Missing → Gap (unless the
  project's convention is "not every ADR makes the index" — judge
  from existing patterns).
- Every index entry points to a file that exists. Broken link →
  Blocker.
- Index entries follow the project's existing order (numeric or
  append-order — read the existing entries to tell). Out of order
  → Nit.

For cross-links:

- Every `Superseded by [ADR-X]` has a matching `Supersedes
  [ADR-Y]` on the other side. Missing pair → Blocker.
- Every "References ADR-N" or `[ADR-N](file.md)` link resolves to a
  file that exists. Broken → Blocker.

Record each Blocker with `<path>:<line>` and the evidence.

### 3. Semantic checks

- **Orphan Proposed.** ADRs in Proposed for >90 days (use
  `git log -1 --format=%cr <file>`). The user may want to accept or
  reject. → Drift.
- **Superseded but still Accepted.** An ADR whose body says
  `Superseded by ADR-N` but whose Status is still `Accepted`.
  Status was not updated when the supersede happened. → Drift.
- **Status legend drift.** A status string used in an ADR that's
  not in the README's documented legend (or, if no README, the
  project's default legend). → Drift.
- **Sibling ADR inconsistency.** Two ADRs that appear to make
  contradictory decisions and neither cross-links the other.
  Flag for human review. → Drift.

Record each as Drift with `<path>:<line> says X` vs evidence at
`<path>:<line>` or command output.

### 4. Coverage checks

- **ADRs missing from README index** (when one is present and the
  convention is "every ADR is indexed"). → Gap.
- **README sections out of date** — status legend doesn't include a
  status that actually appears in ADRs. → Gap.
- **No README index in a project with >10 ADRs.** Mention as a Gap
  (light recommendation, not a Blocker).

### 5. Compile the report

```
## Scope
Audited: <adr-dir>
Repo state: <git rev-parse --short HEAD>, <clean|dirty>
Convention: <detected filename pattern>, <detected section template>
ADR count: <N>

## Blockers
<broken references / numbering / files. Each with <path>:<line> and the evidence. Empty if none.>

## Drift
<load-bearing inconsistencies. Each with <path>:<line> says X vs evidence at <path>:<line>.>

## Gaps
<things that exist but aren't surfaced where they should be (missing index entries, missing status legend rows, etc.).>

## Nits
<minor wording / ordering issues, optional.>

## What still looks accurate
<one or two specific findings — so the user knows you read the whole set.>
```

For every Blocker / Drift / Gap, propose a one-line fix
("update L8 status from 'Accepted' to 'Deprecated' to match the
Superseded-by line at L12", "add a README entry for `adr-14-…`").
Don't write the prose for big rewrites — let the user decide.

### 6. Offer fixes

Use `AskUserQuestion`:

- **Apply mechanical fixes only.** Examples: update an out-of-sync
  Status line for a Superseded-but-still-Accepted ADR; add a
  missing two-way cross-link; add a missing README index entry.
- **Report only.** No edits.

Do not auto-fix Gaps. They typically need new prose or judgment.

If the fix set is large enough to warrant its own PR, suggest the
user run `/track-plan` against the audit report to slice it.

## Edge cases

- **Submodule path referenced** — skip if uninitialized; note in
  the report ("skipped N submodule paths").
- **An ADR file exists but its number doesn't match the project's
  detected pattern** (e.g. someone hand-wrote `quick-note.md` in
  the ADR dir). Surface as Gap with a recommendation to either
  rename or move out of the ADR dir.
- **A reference link points to a renamed file** (file at expected
  number exists with a different slug). Surface as Drift with the
  rename target.
- **The audit surfaces an ADR issue that's really a code issue**
  (e.g. an ADR says "the framework crate has no tokio dependency"
  and `Cargo.toml` says otherwise). Report as Drift but note the
  resolution may be to *fix the code*, not the ADR. Surface
  clearly so the user makes the right call.

## Hard rules

- **Report first.** Never edit during inventory.
- **Mechanical fixes only on confirmation.** Semantic gaps are
  flagged, not auto-filled.
- **Don't delete or renumber.** Renumbering rewrites history;
  surface as a Gap, never auto-fix.
- **Two-way cross-link fixes are paired.** If editing one side
  fails, revert the other.
- **Pair with `/check-claude-md`** when the audit surfaces ADR ↔
  CLAUDE.md drift. Don't try to re-audit CLAUDE.md inside this
  skill; that's a separate skill's job.
