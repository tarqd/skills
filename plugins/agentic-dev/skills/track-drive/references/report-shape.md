# Report shape

Every `track-drive` run emits a structured report. The shape is
stable across runs so a human (or another agent) can scan a stack
of autonomous-orchestrator outputs (e.g. `/goal` re-invocations)
and triage in seconds.

## Why each section earns its place

Each cycle, three classes of information are at risk of getting
lost:

- **Carry-over** — partial work or external blockers that the
  next run must see. Without a stable home, this leaks into PR
  bodies or oral memory and the next run rediscovers it the slow
  way.
- **Follow-up** — observations out of scope for the current
  slice. Without an escape hatch, the agent either expands scope
  (bad) or silently drops the observation (worse). Follow-up is
  both: an escape route for the agent and a triage queue for the
  user.
- **Retrospective** — what went well, what didn't, what should
  change. One sentence per cycle compounds into real learning
  over a phase. Skipping retrospectives is what makes
  month-three feel exactly like month-one.

## Sections

### Run summary

Two lines — policy used and outcome.

```
## Run summary
Policy: report-only
Outcome: slice-3-pr-opened
```

**Policy values** (mirror Step 0): `report-only`,
`issues-for-blockers`, `issues-for-everything`, `per-project`.

**Outcome values** (pick one):

- `slice-N-pr-opened` — implemented a slice; PR #M opened
- `in-flight-N-blocked` — slice N is already in flight; nothing
  started this run
- `waiting-on-prereq-pr-N` — prerequisite PR not yet merged
- `no-actionable-slices` — nothing met the actionable criteria
- `tracking-issue-closed` — parent issue is closed
- `ci-stuck-on-pr-N` — a slice PR has hit the 3-round CI failure
  limit; agent posted a diagnostic and stopped

### What landed

Concrete things this run produced. PR links, branch names,
commit summaries. One-line bullets.

```
## What landed
- Opened PR #214 for slice 3 (claude/track-205-slice-3-snapshot-load)
- Pushed 1 small fix to PR #211 (clippy warning in storage.rs)
```

If nothing landed: write `- (nothing this run)` so the section
isn't empty.

### Carry-over

What the **next** run should pick up. Anything partial, blocked,
or waiting on external state. Each bullet should be specific
enough that a fresh agent can act on it.

```
## Carry-over
- PR #211 (slice 2) awaiting review from @user; do not start new work
- PR #214 (slice 3) CI red on `wasm-check` job — investigate next run
- Slice 5 blocked by ADR-12 ambiguity (#220); raised in Follow-up
```

If nothing to carry: `- (nothing to carry)`.

### Follow-up

The **agent's escape hatch.** Anything you noticed mid-slice that
felt out of scope. Don't fix it; don't expand the slice. Dump it
here.

Format per item: `- <one-line summary> [<issue #N or 'report'>]`

Examples:

```
## Follow-up
- `storage.rs:load()` has duplicated decode logic — could share helper [report]
- `Cargo.toml` declares `tokio` directly in framework crate — ADR-0004 violation [ESCALATED, #221]
- Dead code path in `vat.rs:tick()` (no callers) [report]
```

The `[report]` tag means "noted, no issue created." The
`[ESCALATED, #N]` tag means "escape-hatch override fired — issue
N created regardless of policy." The `[#N]` tag (no escalation
mark) means "policy said to dispatch; issue N created."

Below the bullets, briefly summarize **policy disposition**:

```
Policy applied: report-only.
- 2 follow-ups recorded as report-only.
- 1 escalated (ADR violation) — issue #221 created.
```

### Retrospective

One or two sentences. Honest, not aspirational. Three lenses:

- **What went well?** (or: what was easier than expected)
- **What didn't?** (or: what felt slower / muddier than expected)
- **What should change next cycle?**

You do not need to fill all three — one is fine if it's the only
honest signal. Empty retrospective is the lazy answer; resist it.

```
## Retrospective
The storage trait reshape took longer than expected because
`tests/snapshot.rs` had three fixtures that all needed the same
two-line update — should template these. Otherwise smooth.
```

## What goes where — disambiguation table

| Observation | Goes in |
|---|---|
| Implemented slice N, PR opened | What landed |
| Slice N+1 blocked by a dependency from slice N | Carry-over |
| A different in-flight PR I touched | What landed *(if pushed a fix)* or Carry-over *(if needs review)* |
| Refactor opportunity inside the file I was editing | Follow-up |
| A bug I noticed in unrelated code | Follow-up |
| An ADR violation in code I read | Follow-up *(escalated if previously undocumented)* |
| Build-system gripe (slow tests, flaky CI) | Retrospective |
| Spec was ambiguous; I had to guess | Retrospective + Follow-up *(raise as an issue if blocking)* |
| A pleasant surprise (test fixture made my life easy) | Retrospective |

## Blocker criteria (for the escape-hatch override)

These items get an issue **regardless of policy**:

- **Silent future-slice breakage.** A change exists in main, or
  is being introduced by an in-flight PR, that will silently break
  a future slice (e.g. a dependency upgrade that conflicts with an
  unreleased one, a removed API a future slice expects). Issue
  body must name the breaking change and the future slice it
  affects.
- **Previously-undocumented ADR violation.** Code violates an
  accepted ADR and the violation isn't already tracked in an
  issue. Cite the ADR (`ADR-NN`) and the offending file/line.
- **Security finding.** A leaked secret, a known-vulnerable
  dependency (per `cargo audit` / `npm audit` / similar), or an
  injection-shaped construct in code the agent touched. Open the
  issue with `security` label if the project uses one.

These are deliberately rare. If the agent finds itself escalating
more than once per cycle, the previous cycle's hygiene needs a
look — not the policy.

## Sample full report

```
## Run summary
Policy: issues-for-blockers
Outcome: slice-3-pr-opened

## What landed
- Opened PR #214 for slice 3 (claude/track-205-slice-3-snapshot-load)
- Pushed 1 fix to PR #211 (clippy warning, no review needed)

## Carry-over
- PR #211 (slice 2) awaiting @user review; do not start new work
- Slice 5 blocked: depends on ADR-12 which is still Proposed (#220)

## Follow-up
- `storage.rs:load()` has duplicated decode logic — could share helper [report]
- `Cargo.toml` declares `tokio` directly in framework crate — ADR-0004 violation [ESCALATED, #221]
- Dead code path in `vat.rs:tick()` (no callers) [report]

Policy applied: issues-for-blockers.
- 2 follow-ups recorded as report-only.
- 1 escalated (ADR violation) — issue #221 created.

## Retrospective
Storage trait reshape took longer than expected because three
test fixtures all needed the same two-line update. Worth a small
test helper. Otherwise smooth.
```
