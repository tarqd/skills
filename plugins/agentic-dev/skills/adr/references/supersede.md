# Supersede an existing ADR

Prework completed: directory located, convention detected. (See
[`conventions.md`](conventions.md).)

## Inputs

- `<old-ref>` — required. Number (`14`), filename
  (`0014-postcard.md`), or full path.
- `[<new-ref>]` — optional. If a new ADR file already exists
  (Proposed or Accepted), pass its ref. If not, the new ADR will
  be drafted via the `new` flow.

## Steps

### 1. Resolve the OLD ADR

- Resolve `<old-ref>` to a file path.
- Read its current status. If it's already `Deprecated`,
  `Rejected`, or `Superseded`, stop and ask — superseding an
  already-superseded ADR is suspicious and probably a mistake.
- Read its title (from the H1 header). Cache it.

### 2. Resolve or draft the NEW ADR

- If `<new-ref>` was supplied: resolve to a file path, confirm it
  exists, read its title.
- If `<new-ref>` was not supplied: run the `new` flow (see
  [`new.md`](new.md)) with a title the user provides via
  `AskUserQuestion`. Capture the new ADR's number, path, and
  title.

### 3. Confirm the supersede pair

Use `AskUserQuestion`:

> "ADR-OLD (<title>) is being superseded by ADR-NEW (<title>).
> Proceed?"

Do not skip. Supersedes are load-bearing.

### 4. Edit the OLD ADR

- Status line: change to `Deprecated` (or `Superseded` if the
  project's status legend includes that label — check the cached
  legend from convention detection).
- Insert a "Superseded by" line **immediately under the status
  line**, before the first section / paragraph:

  > Superseded by [ADR-NEW: Title](new-filename.md).

  Use the project's cross-link line shape (from convention
  detection). If the project uses prose links, write prose. If it
  uses bullet lists in References, append a bullet to References
  instead of a top-of-doc line — but the top-of-doc placement is
  preferred for visibility when both shapes are valid.
- Leave the rest of the body **untouched**.

### 5. Edit the NEW ADR

- In its References section, add:

  > Supersedes [ADR-OLD: Title](old-filename.md).

  Match the project's cross-link line shape exactly.
- If the NEW ADR doesn't yet have a References section (because it
  was just drafted with a TODO), add one.

### 6. Update the README index (if present)

- For the OLD entry: update its status hint (or append `(superseded
  by ADR-NEW)` to the summary) to reflect the supersede.
- For the NEW entry: if it isn't already in the index (because the
  new ADR was just drafted in step 2), add it per
  [`new.md`](new.md) step 5.

### 7. Verify two-way link

Read both files post-edit and grep:

- OLD file must contain `Superseded by` AND the link to NEW.
- NEW file must contain `Supersedes` AND the link to OLD.

If either check fails, **revert the other side's edit** and stop
with a diagnostic.

### 8. Report

- Both files edited, paths.
- Two-way link verified.
- Suggested next step: open a PR for the supersede pair as a single
  commit.

## Hard rules

- **Two-way link is mandatory.** If editing one side fails (file
  missing, permission error, unexpected content), revert the other
  side's edit and stop. Do not leave a half-superseded pair.
- **Never delete** the old ADR. Status flip + cross-link only —
  history is preserved.
- **Never auto-merge / auto-commit.** Even after both files are
  edited, the user reviews and commits the supersede.
- **Don't touch the OLD ADR's body** beyond the status line and the
  Superseded-by line. Drive-by edits to a deprecated ADR muddy the
  audit trail.
