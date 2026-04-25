---
name: update-readme
description: Analyze git changes since last README update and intelligently update README with new features, API changes, setup instructions, or breaking changes
compatibility: Works on all platforms with git CLI
user-invokable: true
context: fork
agent: Explore
---

# README Updater

Intelligently analyze git changes since the last README update and determine if any changes warrant documentation updates. Make minimal, precise updates that preserve the existing structure and style.

## Prerequisites

- Git CLI installed and available in PATH
- Current working directory must be in a git repository
- README.md file exists in the repository
- Git history available

## Core Principles

- **Minimal updates only** - don't rewrite or add fluff
- **Preserve existing structure** - keep the README's organization and style
- **Focus on user-facing changes** - features, APIs, setup, breaking changes
- **Ignore internal changes** - refactors, optimizations, minor fixes
- **Keep it concise** - brief, factual, actionable
- **No unnecessary rewrites** - only update sections that need it
- **Match the tone** - follow the existing writing style

## Workflow Steps

### 1. Find Changes Since Last README Update

Get the commit hash where README was last modified:

```bash
# Get the last commit that modified README.md
git log -n1 --format=%H -- README.md
```

Then get all changes since that commit:

```bash
# Get list of changed files with statistics
git diff --find-renames --find-copies --stat "$(git log -n1 --format=%H -- README.md)..HEAD"

# Get summary of commits since last README update
git log --oneline "$(git log -n1 --format=%H -- README.md)..HEAD"
```

### 2. Determine if Updates Are Needed

Analyze the changed files and commits to identify **user-facing changes**:

**Warrant README updates:**
- ✅ New features or functionality
- ✅ API changes (new endpoints, methods, parameters)
- ✅ Breaking changes
- ✅ New setup/installation requirements
- ✅ New dependencies users need to install
- ✅ Changed configuration options
- ✅ New commands or CLI options
- ✅ Significant behavior changes
- ✅ New environment variables required

**Do NOT warrant README updates:**
- ❌ Internal refactoring
- ❌ Code optimizations
- ❌ Minor bug fixes (unless they fix documented behavior)
- ❌ Test updates
- ❌ Dependency version bumps (unless breaking)
- ❌ Documentation-only changes in other files
- ❌ CI/CD changes
- ❌ Code style/formatting changes

### 3. Identify What to Update

If updates are needed, determine which sections:

**Common README sections:**
- **Installation/Setup** - new dependencies, installation steps
- **Usage** - new features, changed APIs, examples
- **Configuration** - new options, environment variables
- **API Reference** - new endpoints, methods, parameters
- **CLI Commands** - new commands or flags
- **Breaking Changes** - incompatible changes
- **Features** - list of features if maintained
- **Requirements** - new system requirements or dependencies

### 4. Read Relevant Files and Context

If updates are needed:

```bash
# Read the current README
cat README.md

# Get detailed diffs for specific files if needed
git diff "$(git log -n1 --format=%H -- README.md)..HEAD" -- path/to/relevant/file.ext
```

Read or search files to understand:
- What the new feature does
- How the API changed
- What new configuration is available
- How to use the new functionality

### 5. Update README Precisely

Make **minimal, targeted updates**:

- Add new features to the feature list
- Add new installation steps if needed
- Update usage examples with new APIs
- Document new configuration options
- Add breaking change warnings
- Update requirements section

**Guidelines for updates:**
- Keep the existing structure and organization
- Match the existing writing style and tone
- Be brief and factual
- Use the same formatting (bullet points, code blocks, etc.)
- Don't rewrite existing content unless necessary
- Add new content in the appropriate sections
- Use proper markdown formatting

### 6. Report Changes

After updating:
- Summarize what was updated and why
- Show the sections that were modified
- Confirm the README is ready for review

## Examples

### Example 1: New feature added

**User**: "Update the README"

**After analysis:**

```bash
git log --oneline "$(git log -n1 --format=%H -- README.md)..HEAD"
```

Output:
```
a1b2c3d feat(api): add user authentication endpoints
e4f5g6h docs: update API examples
```

**Relevant files changed:**
- `src/api/auth.js` (new file)
- `src/routes.js` (modified)

**Analysis:**
- New feature: authentication endpoints
- Warrants README update: ✅ Yes (new API endpoints)

**Actions:**
1. Read README.md to find API section
2. Check `src/api/auth.js` to understand endpoints
3. Update API section with new authentication endpoints:

```markdown
## API Endpoints

### Authentication

- `POST /api/auth/login` - Authenticate user
  - Body: `{ "email": "string", "password": "string" }`
  - Returns: `{ "token": "string", "user": {...} }`

- `POST /api/auth/logout` - Logout user
  - Headers: `Authorization: Bearer <token>`
  - Returns: `{ "success": true }`
```

4. Report: "Updated README API section with new authentication endpoints"

### Example 2: No updates needed

**User**: "Update README"

**After analysis:**

```bash
git log --oneline "$(git log -n1 --format=%H -- README.md)..HEAD"
```

Output:
```
a1b2c3d refactor: extract validation logic
e4f5g6h test: add unit tests for parser
h7i8j9k chore(deps): bump lodash to 4.17.21
```

**Analysis:**
- All changes are internal (refactor, tests, dependency bumps)
- No user-facing changes
- Warrants README update: ❌ No

**Report:**
```
No README updates needed. Changes since last update:
- Internal refactoring
- Test additions
- Dependency updates

None of these affect user-facing documentation.
```

### Example 3: Breaking change

**User**: "Update the README"

**After analysis:**

Commits:
```
a1b2c3d feat!: change config format from JSON to YAML
```

**Analysis:**
- Breaking change: configuration format changed
- Warrants README update: ✅ Yes (breaking change + setup change)

**Actions:**
1. Read README.md
2. Check the config file changes
3. Update Configuration section:

```markdown
## Configuration

⚠️ **Breaking Change in v2.0**: Configuration format changed from JSON to YAML

Create a `config.yaml` file in the root directory:

```yaml
server:
  port: 3000
  host: localhost

database:
  url: postgres://localhost/mydb
  pool: 10
```
```

4. Update migration guide or add note about upgrading from v1.x
5. Report: "Updated README with breaking configuration change"

### Example 4: New installation requirement

**User**: "Update README"

**After analysis:**

Commits:
```
a1b2c3d feat(search): add full-text search with Elasticsearch
```

Files changed:
- `package.json` (added elasticsearch dependency)
- `src/search.js` (new file)
- `docker-compose.yml` (added Elasticsearch service)

**Analysis:**
- New feature requiring external service
- Warrants README update: ✅ Yes (new setup requirement)

**Actions:**
1. Read README.md Installation section
2. Add Elasticsearch requirement:

```markdown
## Installation

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- **Elasticsearch 8+ (new in v2.0)**

### Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start Elasticsearch:
   ```bash
   docker-compose up -d elasticsearch
   ```

3. Run migrations:
   ```bash
   npm run migrate
   ```
```

3. Add search feature to Features section
4. Report: "Updated README with Elasticsearch installation requirement and search feature"

## Edge Cases

### README Doesn't Exist

If no README.md found:
- Inform user: "No README.md found in repository"
- Ask: "Would you like to create one? (yes/no)"
- If yes, create a basic README structure with project info

### No Changes Since Last Update

If README was just updated:
- Report: "README was updated in the most recent commit, no further changes needed"
- Do not make unnecessary updates

### README Never Modified

If `git log -- README.md` returns nothing:
- README might be new or never committed
- Use HEAD as comparison point: `git diff --stat HEAD`
- Proceed with analysis

### Large Number of Changes

If 50+ commits since last README update:
- Summarize by category: features, breaking changes, new requirements
- Focus on the most significant changes
- Ask: "Many changes found. Should I focus on specific areas? (features/api/setup/all)"

### Conflicting Information

If changes conflict with existing README content:
- Flag the conflict to user
- Ask: "Found conflicting info in README. Which is correct?"
- Update only after clarification

### Multiple README Files

If project has multiple READMEs (e.g., `README.md`, `docs/README.md`):
- Ask: "Multiple READMEs found. Which should I update?"
- Update the specified one

## Guidelines

1. **Only update when needed** - don't make changes for the sake of it
2. **Focus on user-facing changes** - internal refactors don't count
3. **Be minimal and precise** - no fluff or rewrites
4. **Preserve structure and style** - match the existing README
5. **Check git history** - use git diff to understand changes
6. **Read the code if needed** - understand what changed before documenting
7. **Keep it factual** - no marketing speak or exaggeration
8. **Use proper markdown** - maintain formatting consistency
9. **Add, don't replace** - preserve existing content unless wrong
10. **Report what you did** - summarize updates for user review

## Anti-Patterns to Avoid

❌ **DO NOT**:
- Rewrite sections that don't need updating
- Add unnecessary fluff or marketing language
- Update for internal changes (refactors, tests)
- Change the tone or style arbitrarily
- Remove existing content without reason
- Make assumptions about changes without reading code
- Update based solely on commit messages

✅ **DO**:
- Make minimal, targeted updates
- Focus on user-facing documentation needs
- Preserve existing structure and style
- Read code/diffs to understand changes
- Update only relevant sections
- Keep the same level of detail as existing content
- Match the existing markdown formatting

## References

- [Make a README](https://www.makeareadme.com/)
- [Awesome README](https://github.com/matiassingers/awesome-readme)
- [README Template](https://github.com/othneildrew/Best-README-Template)
