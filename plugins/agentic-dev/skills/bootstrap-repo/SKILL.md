---
name: bootstrap-repo
description: Bootstrap a local project onto GitHub for agent-driven development. Use when a project has files locally but no git history, no remote, or no initial commit and is about to start phase-1 implementation. Writes a project-appropriate .gitignore, decides the .claude/ versioning policy, stages files explicitly, creates the initial commit, creates the GitHub repo, verifies the push, and hands off to /track-plan.
user-invocable: true
disable-model-invocation: true
---

# bootstrap-repo — get a local project agent-ready on GitHub

Take a project from "files exist locally" to "private GitHub repo with
initial commit pushed, ready for `/track-plan`". Each invocation does
exactly this slice — repo onboarding — and exits. Project-shaped Phase
0 work (CI, dependency policy, ADR scaffolding, CLAUDE.md verification,
README) is surfaced at the end as follow-ups but **not done here**.

## Inputs

Args: `[owner/repo] [--public|--private]`. Both optional; defaults are
inferred from `gh api user` and the cwd, then confirmed via
`AskUserQuestion`.

## Steps

### 1. Preflight

Run in parallel and inspect the results:

- `gh auth status` — must succeed. If it doesn't, end and tell the user
  to run `gh auth login`. Do not attempt to authenticate.
- `git rev-parse --is-inside-work-tree` — if false, `git init -b main`.
- `git remote -v` — if `origin` already exists, end with
  `remote 'origin' already configured: <url>`. Do not modify remotes.
- `git log --oneline -1` — note whether the repo already has commits.
  If it has commits **and** a remote, end with "already on GitHub".
  If it has commits **and** no remote, skip step 6 later (commit
  history is reused as-is).
- `ls docs/phases/` — if a `phase-0*.md` exists, read it. The project's
  own definition of Phase 0 may have additional acceptance criteria
  (CI, deps policy, CLAUDE.md verification, etc.). You will surface
  these in step 9 but you will not do them here.

### 2. Confirm the GitHub target

Default: `{gh-user}/{basename of cwd}`, visibility `private`.

Use `AskUserQuestion` to confirm:

- Owner / repo name (offer the default; allow override).
- Visibility — `private` (recommended) or `public`.

Do not skip. Repo creation is hard to undo: the name may be taken,
or — for public repos — search engines may index before you can
delete.

### 3. Decide the `.claude/` versioning policy

Use `AskUserQuestion` to pick one. Recommend the first.

1. **Selective: ignore `.claude/*`, allowlist shareable subdirs** —
   tracks `skills/`, `hooks/`, `agents/`; ignores `settings.json`
   and any per-machine override:

   ```
   .claude/*
   !.claude/skills/
   !.claude/hooks/
   !.claude/agents/
   ```

2. **Commit everything in .claude/** — including `settings.json` and
   any local overrides. Useful if the team standardises on one config.

3. **Ignore .claude/ entirely** — nothing under `.claude/` lands in
   git.

### 4. Write or augment `.gitignore`

If `.gitignore` exists, **augment** it. Read it first, then append any
missing entries. Never overwrite.

Always add (if missing):

- `.DS_Store`
- `*.local.*`
- `.env`
- `.env.*`
- `!.env.example` (preserve the safe-to-commit template if the repo
  has one)

Language entries — additive, based on presence of the marker file:

- `Cargo.toml` → `target/`
- `package.json` → `node_modules/`, `dist/`, `.next/`
- `pyproject.toml` or `setup.py` → `__pycache__/`, `*.pyc`, `.venv/`,
  `dist/`, `build/`
- `go.mod` → `vendor/` (only if a `vendor/` directory exists)
- `deno.json` / `deno.jsonc` → none required

Append the `.claude/` block from step 3.

### 5. Stage files explicitly

**Never `git add -A` or `git add .`.** Explicit file lists only.

- Run `git status --porcelain` to enumerate working-tree entries.
- Build a single `git add` command naming every top-level file/dir
  that should be tracked.
- Excluded by default: `target/`, `node_modules/`, `.DS_Store`,
  anything matching `*.local.*`, anything not in the `.claude/`
  allowlist from step 3.
- Run `git status` after staging to verify file names. Then run
  `git diff --cached --stat` (or `git diff --cached` for a full
  view) to verify the **content** that's about to land — file
  names alone can mask a stowaway `.env` whose contents include
  secrets. If anything unexpected appears, stop and ask.

### 6. Create the initial commit

Skip if `git log --oneline -1` already shows a commit.

- Title: `Initial commit: {project-name} scaffold`.
  Project-name source order: first heading of `PRODUCT.md`, first
  heading of `README.md`, repo dir basename.
- Body (2–3 lines): one-line description pulled from PRODUCT.md /
  README.md first paragraph + a pointer line — e.g.
  `See PRODUCT.md and docs/adr/ for design.` — included only if those
  files exist.
- If `git log` already has any history, match the existing
  commit-message style (`git log --oneline -20`). Otherwise use the
  default above.
- Do not pass `--no-verify`. Do not skip hooks.

### 7. Create the GitHub repo and push

```
gh repo create {owner}/{name} --{visibility} --source=. --remote=origin --push
```

Capture the URL from stdout.

### 8. Verify

In parallel:

- `git remote -v` — `origin` is set to the new URL.
- `gh repo view {owner}/{name} --json visibility,defaultBranchRef,url`
  — visibility matches, default branch is `main`.

Report: URL, visibility, default branch.

### 9. Surface remaining Phase-0 work

If `docs/phases/phase-0*.md` exists, list its task headings that this
skill did not address — typically CI pipeline, dependency policy /
`deny.toml`, pre-commit hooks, CLAUDE.md verification, ADR scaffold,
README polish. Do not attempt them. Flag them so the user can
slice them via `/track-plan`.

Suggest next step:

> Run `/track-plan @docs/phases/phase-1-*.md` to plan the first
> implementation phase, or `/track-plan @docs/phases/phase-0-*.md` if
> the remaining Phase-0 tasks need PR-sized slices.

## Hard rules

- **Never `git add -A` or `git add .`.** Explicit file lists only — a
  single accidental `add .` can leak `target/`, `.env`, or local
  overrides into the first public commit.
- **Never `git commit -am`.** It silently sweeps in *every*
  tracked-but-modified file. Stage explicitly first, then commit
  without `-a`.
- **Never modify an existing `origin` remote.** If one exists, end.
- **Never force-push, never `git reset --hard`, never `--no-verify`.**
- **Always confirm owner/repo and visibility** via `AskUserQuestion`
  before `gh repo create`. Default to private.
- **Never overwrite an existing `.gitignore`.** Augment it.
- **Stop and ask on broader-state surprises** — pre-existing commits
  with no remote (possibly intentional), unfamiliar branches,
  uncommitted changes you didn't make, an existing `.git/` in an
  unexpected place.
- **One bootstrap per run.** Do not also do Phase-0 task work
  (CI workflow, ADRs, deny.toml, etc.) here — list them as follow-ups
  in step 9.

## Dedup signals (any one = bootstrap already done; end)

- `origin` remote exists.
- `gh repo view {owner}/{name}` succeeds for the inferred target.
- The remote `main` branch already has commits and matches local
  HEAD.

Check via tool calls, never by assumption.
