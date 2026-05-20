# Evolve output — existing repo

The repo already has design artifacts (DESIGN.md, ADRs, phase
docs). The conversation or interview yielded changes — new
decisions, walked-back decisions, scope shifts. **Integrate
changes into the existing artifacts; never auto-edit existing
files. Surface diffs and supersede pairs for the user to apply.**

---

## Step 1: Read the existing state

Cache the existing state before extracting changes:

- Design doc (`DESIGN.md` / `PRODUCT.md` / equivalent) — read in
  full.
- ADR index (`docs/adr/README.md` if present) — read titles +
  statuses.
- Each existing ADR — at minimum: title, status, one-line
  decision, any "Superseded by" lines.
- Phase docs (`docs/phases/phase-*.md`) — titles and goals.

Don't propose changes that contradict what's already established,
and don't restate things that haven't moved.

## Step 2: Classify each change

For each change identified in the design discussion, classify into
one of:

- **New ADR** — a decision that didn't exist before. (Net-new
  feature, new constraint, new pattern.)
- **Supersede ADR** — replaces an existing Accepted ADR. The old
  one gets marked Deprecated/Superseded; the new one references
  it.
- **Walk-back ADR** — an old ADR is being narrowed or partially
  reversed without a clean replacement. Usually still a supersede,
  with the new ADR carrying the narrower scope.
- **Design doc amendment** — the high-level design changes
  (properties added/removed, non-goals shifted). Propose a diff.
- **New phase** — net-new phased work. Add a new
  `phase-N-<slug>.md`; don't rewrite existing phases.
- **Phase amendment** — an existing phase grows tasks or shifts
  acceptance criteria. Propose a diff for that phase file.

If a change doesn't fit any category cleanly, surface it for the
user to clarify before proceeding. Don't force a classification.

## Step 3: Summarize the change set — the gate

Present the planned moves **before generating any files**.
Template:

```
## Proposed changes (target: evolve)

### New ADRs
- ADR-00XX: [Title] — [one-line decision]
- ADR-00YY: [Title] — [one-line decision]

### Supersedes
- ADR-00ZZ ([title]) → ADR-00XX ([new title])
  Why: [one-line reason]

### Design doc amendments
- DESIGN.md "Key properties" — add "Z"; remove "Y"
  (rationale: ADR-00YY)
- DESIGN.md "What it is not" — add "won't W"

### New phase
- docs/phases/phase-N-<slug>.md — [one-line goal]

### Phase amendments
- docs/phases/phase-M-<slug>.md — add task M.X: [one-line]

### Open questions
- [unresolved item]
- [unresolved item]

### Unchanged but verified
- ADR-00AA still accurate
- DESIGN.md "Relationship to alternatives" unchanged
```

Wait for the user to confirm or revise. **Do not generate files
before confirmation.**

If the user approves a **subset** of the change set (e.g. "yes to
the new ADRs, no to the design-doc patch"), regenerate the
change-set summary with only the approved scope and re-confirm
before proceeding. Don't carry rejected items forward silently;
the user dropped them on purpose.

## Step 4: Generate the files (after confirmation)

### New ADRs

Delegate to the `adr` skill's conventions and template:

- **Convention.** Follow what's detected in the existing ADRs
  (see [`../../adr/references/conventions.md`](../../adr/references/conventions.md)).
  The existing project's style wins over the plugin default.
- **Template.** [`../../adr/references/template.md`](../../adr/references/template.md)
  if the project uses Nygard-strict; otherwise match the
  existing project style.
- **Status.** **Accepted** unless the user flagged the item as
  open.
- Add an index entry to `docs/adr/README.md`.

### Supersedes

Delegate to [`../../adr/references/supersede.md`](../../adr/references/supersede.md).
For each pair:

- Edit the OLD ADR: status → `Deprecated` (or `Superseded` if the
  project uses that label), insert
  `Superseded by [ADR-NEW](file.md)` near the top.
- The NEW ADR carries `Supersedes [ADR-OLD](file.md)` in its
  References section.
- Update `docs/adr/README.md` status hint on the old entry.
- The PostToolUse hook in this plugin will nudge if the OLD ADR
  is edited in a way that looks like a body rewrite — heed it.
- Verify the two-way link before moving on (the supersede
  playbook's hard rule).

### Design doc amendments

**Do not auto-edit `DESIGN.md`.** Produce a unified diff or
labeled before/after blocks for each section that changes.
Present as a proposed patch:

```
## DESIGN.md proposed patch

### "Key properties" section
- (remove) Property Y — superseded by ADR-00YY
+ (add)    Property Z — established by ADR-00XX

### "What it is not" section
+ (add)    Won't W — see ADR-00ZZ
```

The user applies the patch manually (or asks the agent to apply
it inline after they review).

### New phase doc

Write `docs/phases/phase-N-<slug>.md` where N is one higher than
the highest existing phase number. Use the Phase N template from
[`bootstrap-output.md`](bootstrap-output.md). Add an entry to
`docs/phases/README.md` if one exists.

### Phase amendments

Produce a diff for the affected phase file, same shape as the
design-doc amendment. **Do not auto-edit.**

## Step 5: Final summary

Present a final summary listing:

- ADRs created (paths + numbers).
- Supersedes wired (pair list — both files touched; two-way link
  verified).
- DESIGN.md patch (proposed, not applied).
- Phase docs created or amended (paths + patch status).
- Open questions still outstanding.

Suggest next moves:

- Review and apply the DESIGN.md / phase amendments.
- If a new phase was added:
  `/track-plan @docs/phases/phase-N-<slug>.md`.
- If the change set affects in-flight work: review open PRs
  against the new ADRs (the PostToolUse hook helps here).
- `/adr audit` after a non-trivial evolve to confirm
  the ADR set is internally consistent.

## Hard rules (evolve-specific)

- **Never auto-edit existing DESIGN.md, existing ADR bodies, or
  existing phase docs.** Always propose a patch and wait. Allowed
  in-place edits to existing files: ADR status flips, "Superseded
  by" lines (via `adr supersede`), and index entries in
  `docs/adr/README.md` / `docs/phases/README.md`.
- **Confirm the change set before generating anything.** Step 3's
  summary is the gate.
- **Don't restate unchanged decisions.** If the conversation
  affirms an existing ADR without modifying it, no action — but
  note it in the summary so the user sees you read it (the
  "Unchanged but verified" block).
- **Don't fabricate supersedes.** Only supersede an ADR if the
  conversation explicitly walked it back. "We're doing X
  differently now" is a supersede; "we should probably also do X"
  is a new ADR.
- **Don't renumber.** New ADRs always extend the numbering;
  numbering gaps from rejected drafts are historical and stay.
