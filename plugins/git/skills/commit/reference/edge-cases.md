# Edge Cases and Special Situations

This file documents how to handle edge cases and special situations when organizing commits.

## No Changes to Commit

If `git status` shows no changes:
- Inform user: "No uncommitted changes found"
- Do not propose any commits
- Do not create empty commits

---

## All Changes are Secrets

If all detected files contain secrets:
- Warn user strongly
- Do not propose any commits
- Suggest proper secret management (env vars, secret managers)

Example:
```
⚠️  Critical Warning: All uncommitted files appear to contain secrets:
- .env
- config/credentials.json
- keys/api-key.pem

These should NEVER be committed to git. Consider:
1. Add these files to .gitignore
2. Use environment variables for configuration
3. Use a secret manager (AWS Secrets Manager, HashiCorp Vault, etc.)

No commits will be created.
```

---

## Merge Conflicts Present

If there are unresolved merge conflicts:
- **Do not propose commits**
- Show conflicted files
- Instruct user: "Please resolve merge conflicts before committing"

Example:
```
❌ Cannot commit: Unresolved merge conflicts detected

Conflicted files:
- src/api/users.js
- src/components/Header.jsx

Please resolve these conflicts first:
1. Edit the files to resolve conflicts
2. Remove conflict markers (<<<<<<<, =======, >>>>>>>)
3. Stage the resolved files with git add
4. Then request commits again
```

---

## Detached HEAD State

If in detached HEAD state:
- Warn user about the state
- Ask: "You're in detached HEAD. Create a branch first? (yes/no)"
- If no, explain implications and proceed with caution

Example:
```
⚠️  Warning: You are in detached HEAD state

This means your commits won't belong to any branch and could be lost.

Create a branch first? (yes/no)

If you choose 'no', commits will be created but you'll need to manually
create a branch or tag to save this work before switching branches.
```

If user says yes:
```bash
git checkout -b feature/my-new-branch
```

---

## Staged + Unstaged Changes

If same files have both staged and unstaged changes:
- Show both `git diff --staged` and `git diff`
- Ask: "Include unstaged changes too? (yes/no/selective)"
- If selective, let user specify per-file

Example:
```
Some files have both staged and unstaged changes:

Staged changes in:
- src/api/users.js (added new endpoint)

Unstaged changes in:
- src/api/users.js (formatting fixes)

Include unstaged changes too? (yes/no/selective)

- yes: Include everything in commits
- no: Only commit staged changes
- selective: Choose per file
```

---

## Very Large Commits

If any proposed commit exceeds 500 lines:
- Warn: "Commit X is large (N lines). Consider breaking it down?"
- Suggest logical splits if possible
- Proceed if user confirms

Example:
```
⚠️  Commit 2 is large (847 lines changed)

Proposed commit:
2. refactor(api): Restructure API layer
   - src/api/users.js (423 lines)
   - src/api/posts.js (312 lines)
   - src/api/comments.js (112 lines)

Consider splitting into:
2a. refactor(api): Restructure users API
2b. refactor(api): Restructure posts API
2c. refactor(api): Restructure comments API

Proceed with single large commit or split? (proceed/split)
```

---

## Empty Commit Messages

If description would be unclear:
- Ask user for clarification: "What does this change accomplish?"
- Incorporate answer into commit message
- Never use generic messages like "update" or "changes"

Example:
```
Cannot determine clear commit message for:
- config/settings.json
- src/config.js

What does this change accomplish?

[Wait for user response, then craft specific message like:]
"feat(config): Add dark mode configuration options"
```

---

## Pre-commit Hook Failures

If commit fails due to pre-commit hooks:
1. **Identify the issue** (linting, formatting, tests)
2. **Fix the issue**
3. **Re-stage fixed files**
4. **Create the commit** (do not use --no-verify)
5. If fixes span multiple concerns, **create separate commits**

Example workflow:
```
Executing commit 1...
❌ Pre-commit hook failed: Prettier formatting errors

Fixing formatting in:
- src/api/users.js
- src/components/Dashboard.jsx

✓ Fixed formatting issues

Re-staging files...
git add src/api/users.js src/components/Dashboard.jsx

Creating commit...
✓ Commit 1 created successfully
```

If fixes create new logical changes:
```
❌ Pre-commit hook failed: ESLint errors found

Fixed 3 linting errors in src/api/users.js
Fixed 2 linting errors in src/components/Dashboard.jsx

Note: Linting fixes are substantial. Creating separate commit:

1. feat(api): Add user authentication endpoint
   - src/api/users.js (feature code)

2. style(api): Fix ESLint errors in users API
   - src/api/users.js (linting fixes)

3. feat(dashboard): Add login form
   - src/components/Dashboard.jsx (feature code)

4. style(dashboard): Fix ESLint errors in dashboard
   - src/components/Dashboard.jsx (linting fixes)
```

---

## Repository with Custom Commit Convention

If `git log` shows the repository uses a different convention than Conventional Commits:
- Detect the pattern
- Ask: "This repo uses custom commit format. Follow it or use Conventional Commits? (custom/conventional)"
- Adapt to their choice

Example:
```
Detected custom commit format in repository:

Recent commits:
- [FEATURE] Add user dashboard
- [BUGFIX] Fix login timeout
- [REFACTOR] Simplify API routing

Use this format or Conventional Commits? (custom/conventional)
```

If custom:
```
Proposed commits:

1. [FEATURE] Add OAuth authentication
   - src/auth/oauth.js
   ...

2. [BUGFIX] Fix token expiry handling
   - src/middleware/auth.js
   ...
```

---

## Partial File Staging

If user has staged only parts of files (using `git add -p`):
- Respect the partial staging
- Only commit the staged portions
- Inform user about unstaged portions

Example:
```
Note: Detected partial file staging

src/api/users.js has:
- Staged: New authentication endpoint (lines 45-89)
- Unstaged: Debug logging (lines 12, 156)

Will commit only the staged authentication endpoint.
Unstaged debug logging will remain uncommitted.
```

---

## Interactive Rebase in Progress

If `git status` shows interactive rebase in progress:
- **Do not create new commits**
- Inform user to complete the rebase first

Example:
```
❌ Cannot commit: Interactive rebase in progress

Please complete the rebase first:
- Continue: git rebase --continue
- Abort: git rebase --abort
- Skip: git rebase --skip

Then request commits again.
```

---

## Cherry-pick in Progress

If `git status` shows cherry-pick in progress:
- Complete the cherry-pick first
- Then proceed with organizing commits

Example:
```
Cherry-pick in progress detected.

Completing cherry-pick...
git cherry-pick --continue

✓ Cherry-pick completed

Now analyzing changes for commit organization...
```
