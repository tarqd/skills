---
name: track-plan
description: Scaffold a GitHub tracking issue with sub-issues from a design doc, ADR, or implementation plan. Use when the user has a spec with multiple slices / phases / migration steps that should land as separate PRs. Confirms the slice breakdown with the user before creating issues. Pairs with /track-drive for execution.
user-invocable: true
disable-model-invocation: true
---

# track-plan — scaffold a tracking issue + sub-issues from a spec

Given a spec document with a multi-step implementation plan, create:

1. A **parent tracking issue** with Status table, dependency map,
   why / scope / acceptance / open questions / references.
2. **Sub-issues** for each slice with goal / scope / out-of-scope /
   acceptance criteria.
3. **Sub-issue links** wiring children to the parent via the GitHub
   sub-issue API.

## Inputs

Args: `<path-to-spec> [owner/repo]`. The spec path is required; the
repo defaults to the current one. If the spec path is missing, ask
the user via `AskUserQuestion`.

## Steps

### 1. Read the spec and project conventions

- Read the spec file in full.
- Read `CLAUDE.md` (or equivalent) for project conventions: labels,
  commit-message style, branch naming, lint/test commands.
- Look at one or two existing tracking issues for template hints:
  `mcp__github__list_issues` filtered by label `tracking`.
- Identify the slice list. Slices are usually called "slices",
  "phases", "migration steps", or a numbered list of PRs the spec
  describes.

### 2. Confirm the slice list with the user

Use `AskUserQuestion` to present the slice titles + one-line
descriptions and offer:

- Approve as-is.
- Edit (let the user paste a revised list).
- Cancel.

Do not skip this step. Slice breakdowns are load-bearing and the
cost of re-creating issues later is non-trivial.

### 3. Compute the dependency map

For each slice, note which earlier slices it depends on. Most
plans are linear (slice N+1 depends on slice N); some branch
(several slices can land after slice 1). Encode as a small block:

```
- slice 1: depends on <prerequisite PR or "none">
- slice 2: depends on slice 1
- slice 3: depends on slice 1
- slice 4: depends on slices 1–3
```

### 4. Create the parent tracking issue (first)

**Create the parent before the children.** The children can then
carry the real parent number from creation, rather than a `TBD`
placeholder that later needs N patches (one per sub-issue) to fix.

Use `mcp__github__issue_write` with `method: create` and a body
that includes:

- Goal paragraph at the top.
- `## Status` table with slice names and **placeholder sub-issue
  numbers** (e.g. `(pending)`). The placeholders get filled in
  step 6 once the sub-issues exist — one patch on this single
  table replaces what would otherwise be N sub-issue patches.
- `## Why` — motivation.
- `## What this changes about other systems` — if it amends or
  supersedes other decisions (ADRs, PLAN.md, etc.).
- `## Acceptance criteria` — overall, typically "all slices landed".
- `## Open questions` — anything the spec flagged as TBD.
- `## Out of scope` — overall.
- `## References` — spec path, related issues / PRs.

Labels: `tracking` plus project convention.

Capture the parent issue number for step 5.

### 5. Create sub-issues (in parallel)

Use `mcp__github__issue_write` with `method: create`, all in a
single message of parallel tool calls. Each sub-issue body
contains:

- `Parent:` reference to the tracking issue from step 4 (real
  number; no placeholder).
- `Depends on:` list of earlier slices.
- `Spec:` file path + section.
- `## Goal` — one paragraph.
- `## Scope` — bullet list of what's in this slice.
- `## Out of scope` — bullet list of what's *not* in this slice;
  explicitly call out drive-by cleanups that should be resisted.
- `## Acceptance criteria` — checkbox list.

Labels: match project convention (read existing labels first; do
not invent new ones).

Capture each created issue's `id` (not just `number`) — step 7
needs the `id`.

### 6. Patch the parent's Status table

`mcp__github__issue_write` with `method: update` on the parent:
replace the placeholder sub-issue numbers in the Status table
with the actual numbers from step 5. Single patch covers every
slice.

### 7. Link sub-issues to the parent

For each sub-issue `id` from step 5, call
`mcp__github__sub_issue_write` with `method: add`,
`issue_number: <parent>`, `sub_issue_id: <child-id>`. Run them
all in parallel.

### 8. Report

Output the parent issue number, the sub-issue list, and the
suggested follow-up:

> Run `/track-drive <parent>` to execute one slice, or hand the
> parent to `/goal` for autonomous progress. Each run emits a
> structured carry-over / follow-up / retrospective report;
> configure the follow-up policy in
> `.claude/agentic-dev.local.md` or `CLAUDE.md` to skip the
> interactive prompt.

## Hard rules

- **Always confirm the slice list with the user** (step 2) before
  creating any issues.
- **Parent first, then children.** The parent's Status table
  starts with placeholders; sub-issues are created with the real
  parent number already in their `Parent:` line. This trades N
  sub-issue patches for one parent-table patch.
- **On partial sub-issue creation failure**, finish the successful
  ones, patch the parent table with what exists (mark the missing
  rows `(failed: <reason>)`), and report the gap. **Do not delete
  the parent.** The parent is the durable artifact; missing
  sub-issues can be re-added later.
- **Never close or modify existing issues** in this skill — the
  only allowed in-place edit is patching the parent's Status
  table you just created in step 4.
- **Use only labels that already exist** in the repo. If a label
  fits but doesn't exist, mention it in the parent body as a
  recommendation, don't create it.
- **Sub-issue bodies should reference the parent**, not duplicate
  it. The parent owns rationale and overall acceptance; the
  sub-issue owns scope and per-slice acceptance.
- **Sizing target: one PR per slice.** If a slice looks like 5+
  files spanning 3+ subsystems (crates, packages, modules,
  services), suggest splitting it further during step 2.
- **Don't invent dependencies.** If the spec doesn't make the
  dependency map explicit, ask the user via `AskUserQuestion`
  before guessing. Wrong dependency wiring blocks `/track-drive`.
