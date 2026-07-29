# agentic-dev

Personal toolkit for using Claude as a coding agent. Five
user-invoked skills that compose into a pipeline from "rough design
discussion" to "tracked, slice-by-slice execution against a
GitHub tracking issue," plus a model-invoked skill for writing the
instruction files those agents read, and an advisory hook that
watches ADR edits.

## Pipeline

```
/design              →  /bootstrap-repo  →  /track-plan      →  /track-drive
 design discussion →    git + GitHub      slice phase into     execute one slice
 produces DESIGN +     onboarding for     parent + sub-issues  → PR, then exit
 ADRs + phase docs     the new docs                            with structured
 (or evolves the                                               carry-over / follow-up
 existing ones)                                                / retrospective report
```

Autonomous progress: hand the parent issue off to `/goal` (or any
external orchestrator). `/track-drive` is idempotent and designed
to be re-invoked.

## Skills

| Skill              | Purpose                                                                 |
| ------------------ | ----------------------------------------------------------------------- |
| **`design`**       | Turn a discussion into a bootstrap document set (DESIGN.md + ADRs + phase docs) on a fresh repo, or evolve those artifacts on an existing one. Auto-detects target; asks when unsure. |
| **`bootstrap-repo`** | Take a local project with files but no git history → `.gitignore`, explicit staging, initial commit, private GitHub repo, push, verify. Hands off to `/track-plan`. |
| **`adr`**          | Manage Architecture Decision Records — propose new, supersede / accept / reject existing, audit the set for drift. Detects project convention; never invents a format. |
| **`track-plan`**   | Scaffold a parent tracking issue + sub-issues from a spec doc (phase, ADR, migration plan). Parent-first creation; user confirms the slice list before any issues are created. |
| **`track-drive`**  | Drive a tracking issue toward completion. One slice per run; idempotent. Exits with a structured carry-over / follow-up / retrospective report. Step-0 policy gate decides how follow-ups are dispatched. |
| **`claude-prompting`** | How to write the instructions Claude reads as an agent — CLAUDE.md, AGENTS.md, SKILL.md, subagent and slash-command definitions. Covers the over-prompting trap, instructions that used to help and now backfire, per-model behavior deltas across the Claude 5 series, and which model to hand a task to. |

The five pipeline skills are `user-invocable: true` +
`disable-model-invocation: true` — invoke explicitly via slash
command; nothing auto-triggers. `claude-prompting` is the exception:
it is model-invoked, so it surfaces on its own whenever an
instruction file is being written, reviewed, or debugged.

## Hook

**`hooks/check-adr-edit.sh`** (PostToolUse on Edit/Write/MultiEdit)
— advisory consistency check that fires when an ADR file is
edited. Non-blocking; emits a `systemMessage` with any findings.

Checks:

- H1 looks like an ADR header
- `**Status:**` line present
- Filename number matches H1 number (zero-pad tolerant)
- Nudges about `adr supersede` when an Accepted/Deprecated/Superseded ADR's body is edited in place
- Warns when editing an ADR with a `Superseded by` marker (historical)

Silent on non-ADR paths, non-Edit tools, README/TEMPLATE files.
Gracefully no-ops if `jq` isn't installed.

## Configuration

For `track-drive`, the follow-up policy can be set per-project so
scheduled runs don't block on `AskUserQuestion`. Sources (local
overrides repo):

1. `.claude/agentic-dev.local.md` (frontmatter:
   `track-drive.follow-up-policy`)
2. `CLAUDE.md` (`## track-drive policy` section)
3. Interactive ask (when no orchestrator context detected)
4. Default: `report-only`

Values: `report-only` (recommended), `issues-for-blockers`,
`issues-for-everything`.

## Layout

```
plugins/agentic-dev/
  .claude-plugin/plugin.json
  hooks/
    hooks.json
    check-adr-edit.sh
  skills/
    adr/
      SKILL.md
      references/
        conventions.md       ← detect filename/header/section style
        new.md               ← propose a new ADR
        supersede.md         ← two-way cross-link wiring
        audit.md             ← Blockers/Drift/Gaps report shape
        template.md          ← canonical Nygard-strict body
    bootstrap-repo/SKILL.md
    design/
      SKILL.md
      references/
        bootstrap-output.md  ← fresh-repo file layout + templates
        evolve-output.md     ← change-set classification + integration
        phase-shapes.md      ← phase arcs + sizing heuristics
    track-drive/
      SKILL.md
      references/
        report-shape.md      ← section detail, disambiguation table, sample
    track-plan/SKILL.md
    claude-prompting/
      SKILL.md
      references/
        model-selection.md   ← 5-series lineup, delegation, effort
        opus-5.md            ← per-model behavior deltas
        sonnet-5.md
        fable-5.md
        opus-4-8.md
        snippets.md          ← tested instruction blocks
```

## Conventions baked in

- **ADRs:** 4-digit zero-padded filenames (`NNNN-slug.md`),
  Nygard-strict sections (Context / Decision / Alternatives
  Considered / Consequences / References), `docs/adr/README.md`
  index with status legend. Detected convention wins over the
  default when ADRs already exist.
- **Phase docs:** one file per phase under `docs/phases/`
  (`phase-N-<slug>.md`) so `/track-plan` can consume each as a
  spec.
- **Branches:** `claude/track-{parent}-slice-{N}-{short-summary}`.
- **Commits:** explicit `git add <file>` lists — never
  `git add -A`, never `git commit -am`, never `--no-verify`.
- **Authors:** ADR conventions delegate to the `adr` skill; design
  skill never duplicates them.

## Not in scope

- Worktrees and parallel-agent orchestration (orthogonal; use
  whatever orchestrator you prefer).
- Code review automation (use `/ultrareview` or similar).
- Build / test execution beyond what `track-drive` runs per slice.
