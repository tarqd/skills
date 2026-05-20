# Bootstrap output — fresh repo

The repo has no existing design artifacts (or the user chose
"treat as fresh" in hybrid mode for the missing pieces). Write
everything from scratch.

## File layout

In Claude Code (repo on disk), write the files at these paths —
this is the layout the rest of the agentic-dev pipeline expects:

```
DESIGN.md                       (some projects prefer PRODUCT.md;
                                 honor an existing one if found)
docs/adr/README.md              ← ADR index + status legend
docs/adr/0001-<slug>.md         ← one file per ADR
docs/adr/0002-<slug>.md
...
docs/phases/README.md           ← phases index
docs/phases/phase-0-scaffold.md
docs/phases/phase-1-<slug>.md
...
```

In a Claude.ai conversation (no repo), emit them inline as
labeled markdown blocks; the user pastes each into the matching
file.

**If any of these files already exist, stop and ask** before
overwriting. Bootstrap docs are load-bearing; clobbering by
surprise is high-cost.

Suggested write/emit order:

1. `DESIGN.md`
2. `docs/adr/README.md` (the index)
3. ADRs (one after another)
4. `docs/phases/README.md`
5. Phase files (one after another)

## DESIGN.md template

```markdown
# [Project Name]

## What it is

[1–2 paragraphs. What the thing does, who it's for, why it exists.
Concrete enough that a developer reading it knows whether this is
relevant to them in 30 seconds.]

## Key properties

[4–6 bullets. Properties the design is optimizing for — things a
user would notice and care about. Not a feature list. Each bullet
gets 1–2 sentences of elaboration.]

## What it is not

[2–4 bullets on explicit non-goals. Scope boundaries. What the
user should reach for something else for.]

## Relationship to alternatives

[Optional. A short table or list comparing to the 2–3 most relevant
alternatives. Focus on meaningful differences, not full coverage.]
```

## ADRs

Delegate the format and conventions to the `adr` skill — don't
duplicate the template here. Follow the canonical Nygard-strict
default in
[`../../adr/references/template.md`](../../adr/references/template.md):

- Filename: `NNNN-slug.md` (4-digit zero-padded).
- Header: `# ADR-NNNN: Title`.
- Sections: Context / Decision / Alternatives Considered /
  Consequences (Positive/Negative) / References.

Status of newly-generated ADRs: **Accepted** (the design
discussion confirmed them). Use `Proposed` only for items the
user explicitly flagged as open.

For the index, write `docs/adr/README.md`:

```markdown
# Architecture Decision Records

## Index
- [ADR-0001: Title](0001-title.md) — one-line summary.
- ...

## Status legend
- **Accepted** — in effect
- **Proposed** — under discussion
- **Deprecated** — superseded
- **Rejected** — considered and not adopted
```

## Phase docs

**Phase 0 is always project scaffolding.** Subsequent phases build
toward the demo, then v0.1.

Write one file per phase under `docs/phases/`:

```
docs/phases/
  README.md                     ← brief description of each phase
  phase-0-scaffold.md
  phase-1-<slug>.md
  phase-2-<slug>.md
  ...
```

### Phase 0 template (always include)

Adapt task names and acceptance criteria to the language and
ecosystem. The six areas below are always present; how they're
implemented is the coding agent's call.

```markdown
# Phase 0: Project Scaffolding

**Goal:** A repository where a coding agent can work reliably from
day one.

**Note to coding agent:** These tasks describe *what* to achieve,
not *how*. Choose tools and conventions appropriate to the
language and ecosystem. Where the design doc is silent, use good
judgment.

## Tasks

### 0.1 Repository structure
Set up the project layout appropriate to the language and design
doc: source directories, test directories, example or demo
directories.
- [ ] Project builds/compiles successfully from a clean clone.
- [ ] Test runner executes with no tests (zero failures, no errors).

### 0.2 CI pipeline
Automated checks on every push and pull request. Choose tooling
appropriate to the ecosystem (GitHub Actions, etc.).
- [ ] Linting and formatting checks run in CI.
- [ ] Tests run in CI.
- [ ] A build check runs for every target platform mentioned in
      the design doc.
- [ ] CI passes on the initial empty scaffold.

### 0.3 Dependency policy
Enforce the constraints in the ADRs about allowed/disallowed
dependencies.
- [ ] Dependencies are consistent with what the ADRs specify.
- [ ] Any feature-flag or optional-dependency patterns from the
      design are scaffolded (even if empty).

### 0.4 Pre-commit hooks
Fast local checks before commits land.
- [ ] Formatting check runs on commit.
- [ ] Basic build/lint check runs on commit.
- [ ] Hook installs in one command for a new contributor.

### 0.5 Agent instructions (CLAUDE.md)
A file at the repo root that tells a coding agent what this
project is, what the hard constraints are, and how to verify
work.
- [ ] References the design doc and ADR index.
- [ ] Lists the must-not-violate constraints from the ADRs.
- [ ] Includes exact commands for building, testing, and linting.
- [ ] A new agent could start Phase 1 from this file alone.

### 0.6 README
- [ ] One-paragraph description matching the design doc.
- [ ] How-to-build or quick-start section.
- [ ] Link to ADR index.
```

### Phase N template

```markdown
# Phase N: [Name]

**Goal:** [One sentence. What capability exists at the end of this
phase that didn't before. Should be demonstrable — something you
can run and see.]

**Builds on:** Phase N-1

## Tasks

### N.1 [Task name]
[2–4 sentences. What to implement. Specific enough that the agent
knows what done looks like. Avoid over-specifying implementation;
describe the shape, not the code.]

Acceptance criteria:
- [ ] [Specific, testable. Not "it works" but "sending X returns Y".]
- [ ] [...]

### N.2 ...
```

For sizing guidance (tasks per phase, days per task, etc.) and
alternative phase arcs (CLIs, web services, AI apps), see
[`phase-shapes.md`](phase-shapes.md).

## After writing

Suggest next moves:

- `/bootstrap-repo` to get the docs onto GitHub.
- `/track-plan @docs/phases/phase-0-scaffold.md` (or
  `phase-1-…`) to slice the first phase into a tracking issue +
  sub-issues.
