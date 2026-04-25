---
name: commit
description: Analyze uncommitted changes and create logical, atomic commits using Conventional Commits format. Use when user requests to commit changes, organize commits, or create a commit structure. Handles commit message formatting, grouping by concern (features/fixes/refactors), secret detection, and pre-commit hook failures.
argument-hint: [optional, feature or set of changes to create commits for]
user-invokable: true
context: fork
agent: Explore
---

# Git Commit Organizer

Analyze uncommitted changes and propose logical, atomic commit structure following Conventional Commits format.

## Prerequisites

- Git CLI installed and available in PATH
- Current working directory in a git repository

## Safety Protocol

- **NEVER update git config**
- **NEVER run destructive git commands** (push --force, hard reset) unless explicitly requested
- **NEVER skip hooks** (--no-verify, --no-gpg-sign) unless explicitly requested
- **NEVER force push to main/master** - warn if requested
- **ALWAYS create NEW commits** - NEVER use `git commit --amend` unless explicitly requested
- **NEVER commit secrets** - exclude `.env`, `credentials.json`, `*.pem`, `*.key` automatically
- **Only commit when user explicitly requests**

## Core Workflow

### 1. Analyze Repository State (Parallel)

Run these commands in parallel:

```bash
git status
git diff HEAD
git log --oneline -10
```

### 2. Check for Secrets

Before proposing commits, scan for secret files:
- `.env`, `.env.local`, `.env.production`
- `credentials.json`, `secrets.yaml`, `*.pem`, `*.key`
- `config/secrets.*`, `.aws/credentials`

If found: **warn user**, **exclude from commits**, **suggest .gitignore**

### 3. Propose Logical Commit Groups

Break changes into atomic commits by concern:

**Grouping priority:**
1. `chore(deps):` - Dependency updates
2. `refactor(scope):` - Code restructuring
3. `feat(scope):` - New features
4. `fix(scope):` - Bug fixes
5. `test(scope):` - Tests
6. `docs:` - Documentation
7. `style(scope):` - Formatting
8. `build:` or `ci:` - Build/CI config

**Commit message format:**
```
type(scope): Description starting with capital letter

[Optional body explaining what/why, wrapped at 72 chars]

[Optional footer with issue refs]
```

**Subject line rules (≤50 chars):**
- Capitalize first letter
- Use imperative mood ("Add" not "Added")
- No trailing period
- Test: "If applied, this commit will _[subject]_"

See `reference/conventional-commits.md` for complete format specification.

### 4. Present Plan

Format:
```
Proposed commits:

1. type(scope): Description
   - file1.ext
   - file2.ext

   Body: Brief explanation of what problem this solves and why.

   Fixes: #123

2. type(scope): Description
   - file3.ext

   Body: Context if needed.

Proceed with these commits? (yes/no/revise)
```

### 5. Get User Approval

- **"yes"** → Execute commits
- **"no"** → Stop without committing
- **"revise"** → Ask what to change, present updated plan

### 6. Execute Commits (Sequential)

For each approved commit:

```bash
# Stage files explicitly
git add <file1> <file2> <file3>

# Create commit using HEREDOC for proper formatting
git commit -m "$(cat <<'EOF'
type(scope): description

Optional body explaining why this change was made.
EOF
)"

# Verify success
git status
```

**Critical:**
- Add files **explicitly** (never `git add .` or `git add -A`)
- Use **exact message** from plan
- **Verify success** before next commit
- If commit **fails**, report error and stop

### 7. Handle Pre-commit Hook Failures

If commit fails due to hooks:
1. **Identify issue** (linting, formatting, tests)
2. **Fix the issue**
3. **Re-stage fixed files**
4. **Create commit** (do NOT use --no-verify)
5. If fixes span multiple concerns, **create separate commits**

### 8. Post-Commit Verification

After all commits:
- Run `git status` to confirm clean state
- Show summary of created commits
- **Do NOT push** unless user explicitly asks

## Example

**User**: "Commit my changes"

**After analysis:**

```
Proposed commits:

1. chore(deps): Update axios to 1.6.0
   - package.json
   - package-lock.json

   Body: Addresses CVE-2023-xxxx security vulnerability in axios.
   Previous version allowed potential header injection attacks.

2. refactor(api): Extract auth logic to middleware
   - src/middleware/auth.js
   - src/routes/users.js
   - src/routes/posts.js

   Body: Authentication logic was duplicated across route handlers,
   making it difficult to maintain consistent auth behavior. This
   extracts the logic into reusable middleware, reducing duplication
   and making future auth changes easier to implement consistently.

3. feat(users): Add email verification endpoint
   - src/routes/users.js
   - src/services/email.js
   - src/templates/verify-email.html

   Body: Implements POST /users/verify endpoint to verify user email
   addresses via token sent during registration. This reduces spam
   accounts and ensures we can reliably contact users.

4. test(users): Add tests for email verification
   - tests/users.test.js

   Body: Covers success case, invalid token, and expired token
   scenarios to ensure verification flow works correctly and fails
   safely for edge cases.

Proceed with these commits? (yes/no/revise)
```

For more examples, see `reference/examples.md`

## Commit Organization Principles

- **Never commit everything as one blob** - break into logical units
- **Separate concerns** - refactors ≠ features ≠ fixes ≠ deps
- **Don't mix formatting with logic changes**
- **Dependencies get their own commit**
- **Config changes separate from code changes**
- **Each commit should be atomic and deployable**

## Common Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, whitespace (no code change)
- `refactor`: Code change that neither fixes bug nor adds feature
- `test`: Adding or correcting tests
- `chore`: Build process, tooling, dependencies
- `perf`: Performance improvement
- `ci`: CI configuration
- `build`: Build system or external dependencies

## Edge Cases

For handling special situations, see `reference/edge-cases.md`:
- No changes to commit
- All changes are secrets
- Merge conflicts
- Detached HEAD state
- Staged + unstaged changes
- Very large commits
- Pre-commit hook failures
- Custom commit conventions

## References

- `reference/conventional-commits.md` - Complete Conventional Commits specification
- `reference/examples.md` - Additional detailed examples
- `reference/edge-cases.md` - Edge cases and special situations
