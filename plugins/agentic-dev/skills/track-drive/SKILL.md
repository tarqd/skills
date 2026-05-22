---
name: track-drive
description: >-
  Drive a GitHub tracking issue one step toward completion. Inspects PR and
  issue state, picks the next actionable sub-issue respecting dependencies
  and dedup signals, implements one slice, opens a PR, then exits with a
  structured report (carry-over / follow-up / retrospective). Use when the
  user wants to advance a tracking issue by one slice — typically paired
  with /track-plan, and often re-invoked by an external orchestrator
  (e.g. /goal) for autonomous progress. Idempotent — GitHub state is the
  only source of truth between runs.
user-invocable: true
disable-model-invocation: true
---

# track-drive — execute one step of a tracking issue

Drive a tracking issue toward completion. Each invocation does at
most one slice's worth of work and exits with a structured report.
Idempotent so an external orchestrator (e.g. `/goal`) can re-invoke
safely until the tracking issue is closed.

**GitHub state is the only source of truth.** No memory between
runs. Every dedup decision is made by reading issue / PR / branch
state via `mcp__github__*` tools.

**The follow-up section is the agent's escape hatch.** When you
notice something out of scope mid-slice — a tempting refactor, a
nearby bug, an ADR-adjacent question — do not expand scope. Dump
the observation into the report's Follow-up section and keep going.
That escape route is what lets a single-slice contract hold under
real codebases.

## Inputs

Args: `<tracking-issue-number> [owner/repo]`. The issue number is
required; the repo defaults to the current one. If the issue
number is missing, ask the user via `AskUserQuestion`.

## Step 0: Establish follow-up policy

Before any work, determine how follow-ups will be handled this run.
Policy is fixed for the duration of the run and recorded in the
end report.

Sources, in priority order (local overrides repo):

1. **`.claude/agentic-dev.local.md`** — if present, read its
   frontmatter for `track-drive.follow-up-policy`. Local config
   wins so a per-checkout policy can override what's in the repo.
2. **`CLAUDE.md`** — look for a `## track-drive policy` section
   naming one of the policy values below.
3. **Interactive ask** — only when no autonomous orchestrator is
   driving the run (no `/goal` or similar context detectable; the
   user is sitting in front of the session). `AskUserQuestion`
   with the values below.
4. **Default** (no policy file, orchestrator-driven run) — use
   `report-only`. Note the missing policy in the report so the
   user can set it permanently.

Policy values (these are also the `AskUserQuestion` options when
source 3 fires):

- **`report-only`** *(recommended; default).* List follow-ups in
  the end report. Create no issues. User triages.
- **`issues-for-blockers`.** Create issues only for items meeting
  the **blocker criteria** below. Other follow-ups remain in the
  report.
- **`issues-for-everything`.** Create an issue for every concrete
  follow-up. Use sparingly — noisy.

**Blocker criteria** (the high-bar set that always escalates,
regardless of policy — see Hard rules below for the override
case):

- A future slice will fail or produce wrong output without this
  fix.
- A previously-unrecorded ADR violation has been found in the
  code.
- A security finding: a leaked secret, a known-vuln dependency,
  an injection-shaped construct.

Anything not in that list is **not** a blocker, even if it feels
important.

**Anti-example** (resist the rationalization): "Code adjacent to
my slice that could be cleaner" is **not** silent future-slice
breakage, even if I think the next slice would be cleaner with
it fixed first. That's a Follow-up bullet, not `[ESCALATED]`.
"Dead code in the file I'm editing" — Follow-up.
"Test helper I wish existed" — Follow-up. The blocker bar is
narrow on purpose.

## Step 1: Inspect the tracking issue

- Read parent body via `mcp__github__issue_read` (`method: get`).
- Parse the `## Status` table → slice → sub-issue map.
- Parse the dependency map (look for "Dependency map" block or
  `Depends on:` lines in sub-issue bodies).
- If the parent is closed, end with "tracking issue closed".

## Step 2: Gate on prerequisite PRs

If the parent references a "must merge first" PR (often the spec /
ADR itself, or a foundation slice):

- **Open?** End. Report "waiting on PR #N" in Carry-over.
- **Closed unmerged?** End and ask the user via
  `AskUserQuestion` whether to proceed without it.
- **Merged?** Proceed.

## Step 3: Triage in-flight slice PRs

List open PRs whose head branch matches
`claude/track-{parent}-slice-*` OR whose body references any
sub-issue from step 1.

For each:

- **CI red?** Investigate. Small unambiguous fix → push it.
  Ambiguous → `AskUserQuestion` and stop.
- **Unresolved actionable review threads?** Address tractable
  ones (small, clear). Ask on ambiguous ones.
- **Approved + green?** Do nothing (user merges).
- **Open, no feedback yet?** Do nothing.

**If any slice PR is in flight, end the run.** Do not start new
work concurrently. Carry-over reports which slice is in flight.

## Step 4: Pick the next actionable slice

A slice is **actionable** iff *all* of:

1. Its sub-issue is open.
2. No `in-progress` label on the sub-issue.
3. No assignee other than the bot identity (none is also fine).
4. No remote branch `claude/track-{parent}-slice-{N}-*` exists.
5. No open PR references the sub-issue number.
6. All dependencies in the dependency map are merged (their
   sub-issues are closed AND their PRs are merged).

From the actionable set, pick the **lowest-numbered slice**. If
empty, end the run with the structured report (see Step 8); list
in-flight and blocked slices under Carry-over.

## Step 5: Implement the slice

- Branch: `claude/track-{parent}-slice-{N}-{short-kebab-summary}`.
- Read the sub-issue body and the spec section it references.
  **Stay strictly inside its "Scope".** Do not expand into items
  in "Out of scope," even when an obvious cleanup tempts you.
  When tempted: write it into Follow-up and keep going.
- Run project checks per `CLAUDE.md` (fmt / lint / build / test).
- Commit in small, reviewable chunks; match the repo's
  commit-message style (check `git log --oneline -20`).
- Doc-only slices may skip the test run.
- Push with `git push -u origin <branch>`.

## Step 6: Open a PR

- Title: `{primary scope}: {one-line summary} (#{slice-issue})`.
- Body:
  - `## Summary` — 3–5 bullets.
  - `## Test plan` — checkbox list.
  - `Closes #{slice-issue-number}`.
- Use `mcp__github__create_pull_request` with base `main`.

## Step 7: Subscribe

- `mcp__github__subscribe_pr_activity` for the new PR.

## Step 8: Structured end-of-run report

Always emit the report, even when no slice was picked (e.g.
in-flight slice blocked the run). Section shape, outcome values
(`slice-N-pr-opened`, `in-flight-N-blocked`,
`waiting-on-prereq-pr-N`, `no-actionable-slices`,
`tracking-issue-closed`, `ci-stuck-on-pr-N`), dispatch
disposition format, and a worked sample are all in
[`references/report-shape.md`](references/report-shape.md).

If the policy created any issues this run, list each follow-up
with its dispatched issue number. If the escape-hatch criteria
(see Hard rules) fired, prefix the item with **[ESCALATED]** and
note why.

## Hard rules

- **One slice per run.** Even if a PR is opened and CI is fast,
  do not pick up another slice in the same run.
- **No force-pushes, no destructive git, no merging, no closing
  issues.**
- **Never edit the spec itself.** If the spec is ambiguous, ask
  via `AskUserQuestion` and stop.
- **If CI has failed 3+ rounds on a PR, stop pushing.** Post a
  single diagnostic comment summarising what you tried and end.
- **Honour Out-of-scope lists.** No drive-by cleanups. Use the
  Follow-up section instead.
- **Respect `CLAUDE.md` conventions** (lint rules, forbidden
  patterns, etc.).
- **Stop and ask on broader-state surprises** — uncommitted
  changes on main, unfamiliar branches you didn't create, the
  spec PR reverted, etc.
- **Always emit the end-of-run report** — even on early exit.
  Even when there's nothing to carry over, the section headers
  appear (empty if nothing applies). Stable shape lets the user
  scan runs at a glance.
- **Escape-hatch override.** Regardless of policy, **always**
  create an issue for items meeting the **blocker criteria** in
  Step 0 (silent future-slice breakage, undocumented ADR
  violation, security finding). Mark these `[ESCALATED]` in the
  report so the override is visible. This is the *only* case
  where the policy is ignored.
- **Never dispatch issues for items below the blocker bar** unless
  policy explicitly says so. "While I was here, X could be
  cleaner" is not an issue. It's a Follow-up bullet.

## Dedup signals (any one = something is already on it; skip)

- Sub-issue closed.
- Sub-issue has `in-progress` label or non-bot assignee.
- Remote branch `claude/track-{parent}-slice-{N}-*` exists.
- Open PR mentions `#{slice-issue}` in title or body.

Check these via `mcp__github__*` tools, never by assumption.

## Why the report shape matters

The report's stable shape is what makes autonomous re-invocation
(via `/goal` or similar) actually useful: a human can scan ten
runs in a minute and triage. Full motivation — why each of
carry-over / follow-up / retrospective earns its place — is in
[`references/report-shape.md`](references/report-shape.md).
