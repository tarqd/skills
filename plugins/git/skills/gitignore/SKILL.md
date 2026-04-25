---
name: gitignore
description: Analyze project structure and create or update .gitignore file with appropriate patterns for the detected tech stack
user-invokable: true
context: fork
agent: Explore
---

# Gitignore Manager

Intelligently analyze the current directory structure and create or update an appropriate `.gitignore` file based on detected project type, tech stack, and existing patterns.

## Core Principles

- **Minimal and standard patterns** - avoid overly broad ignores
- **Preserve custom entries** - when updating existing .gitignore, keep user-specific patterns
- **Never ignore source code** - only ignore generated files, dependencies, and secrets
- **Never ignore essential config** - keep configuration that should be versioned
- **Organize with comments** - group patterns by category for maintainability
- **Use .gitignore, not global excludes** - project-specific ignores belong in the repo

## Workflow Steps

### 1. Detect Project Type

Check for language/framework-specific files in the current directory and subdirectories:

**Node.js/JavaScript:**
- `package.json`
- `package-lock.json`
- `yarn.lock`
- `pnpm-lock.yaml`

**Python:**
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`

**Rust:**
- `Cargo.toml`
- `Cargo.lock`

**Go:**
- `go.mod`
- `go.sum`

**Java:**
- `pom.xml`
- `build.gradle`
- `build.gradle.kts`

**Ruby:**
- `Gemfile`
- `Gemfile.lock`

**PHP:**
- `composer.json`

**.NET/C#:**
- `*.csproj`
- `*.sln`

**Swift:**
- `Package.swift`

### 2. Analyze Directory Structure

Use appropriate commands to identify patterns to ignore:

```bash
# Find common directories that should be ignored
find . -type d -name "node_modules" -o -name "dist" -o -name "build" -o -name ".venv" -o -name "__pycache__" 2>/dev/null | head -20

# Find common files that should be ignored
find . -name "*.log" -o -name ".DS_Store" -o -name ".env" -o -name "*.tmp" 2>/dev/null | head -20

# Check for IDE/editor directories
ls -a | grep -E "^\.vscode$|^\.idea$|^\.fleet$"
```

Identify:
- **Build outputs**: `dist/`, `build/`, `target/`, `out/`, `.next/`, `_site/`
- **Dependency directories**: `node_modules/`, `vendor/`, `.venv/`, `venv/`, `env/`
- **IDE/editor files**: `.vscode/`, `.idea/`, `.fleet/`, `*.swp`, `.DS_Store`
- **Environment files**: `.env`, `.env.local`, `.env.*.local`
- **Log files**: `*.log`, `logs/`
- **Cache directories**: `.cache/`, `__pycache__/`, `.pytest_cache/`, `.parcel-cache/`
- **Temporary files**: `tmp/`, `temp/`, `*.tmp`, `*.temp`
- **OS-specific**: `.DS_Store`, `Thumbs.db`, `desktop.ini`

### 3. Check for Existing .gitignore

```bash
# Check if .gitignore exists
ls -la .gitignore 2>/dev/null
```

If `.gitignore` exists:
- **Read current contents**
- **Identify custom user patterns** (anything not in standard templates)
- **Preserve custom patterns** when updating
- **Remove duplicates**
- **Organize into sections**

If `.gitignore` does not exist:
- **Create new file** with appropriate patterns

### 4. Build .gitignore Content

Organize patterns into logical sections with comments:

```gitignore
# Dependencies
node_modules/
vendor/

# Build outputs
dist/
build/
*.js.map

# Environment variables
.env
.env.local
.env.*.local

# Logs
*.log
logs/

# OS-specific
.DS_Store
Thumbs.db

# IDE/Editor
.vscode/
.idea/
*.swp
*~

# Cache
.cache/
__pycache__/
*.pyc

# Temporary files
tmp/
*.tmp
```

### 5. Write or Update .gitignore

- **Create** `.gitignore` if it doesn't exist
- **Update** existing `.gitignore` by merging standard patterns with custom entries
- **Remove duplicates**
- **Sort within sections** (optional, for cleanliness)

### 6. Verify and Report

```bash
# Check what's currently tracked that should be ignored
git ls-files -ci --exclude-standard

# Show the new/updated .gitignore
cat .gitignore
```

Report to user:
- What was added/updated
- Any currently tracked files that should be ignored
- Suggestion to remove tracked files if needed: `git rm --cached <file>`

## Language/Framework-Specific Patterns

For detailed language-specific gitignore patterns, see the reference files:

- [Node.js/JavaScript/TypeScript](reference/Node.gitignore)
- [Python](reference/Python.gitignore)
- [Rust](reference/Rust.gitignore)
- [Go](reference/Go.gitignore)
- [Java](reference/Java.gitignore)
- [Ruby](reference/Ruby.gitignore)


## Examples

### Example 1: New Node.js project

**User**: "Create a .gitignore for this project"

**Expected behavior:**

1. Detect `package.json` → Node.js project
2. Find `node_modules/` and `dist/` directories
3. Create `.gitignore` with Node.js patterns:

```gitignore
# Dependencies
node_modules/

# Build outputs
dist/
build/
*.js.map

# Environment variables
.env
.env.local

# Logs
npm-debug.log*
yarn-debug.log*
*.log

# OS-specific
.DS_Store
Thumbs.db

# IDE/Editor
.vscode/
.idea/
*.swp
*~

# Testing
coverage/
.nyc_output/
```

4. Report: "Created .gitignore for Node.js project with 15 patterns"

### Example 2: Update existing .gitignore

**User**: "Update my .gitignore"

**Existing .gitignore:**
```gitignore
node_modules/
dist/

# My custom pattern
secret-notes.txt
```

**Expected behavior:**

1. Read existing .gitignore
2. Identify custom pattern: `secret-notes.txt`
3. Detect project type: Node.js
4. Merge standard Node.js patterns with custom entries:

```gitignore
# Dependencies
node_modules/

# Build outputs
dist/
build/

# Environment variables
.env
.env.local

# Logs
*.log
npm-debug.log*

# OS-specific
.DS_Store
Thumbs.db

# IDE/Editor
.vscode/
.idea/
*.swp

# Testing
coverage/

# Custom
secret-notes.txt
```

5. Report: "Updated .gitignore, preserved custom pattern: secret-notes.txt"

### Example 3: Multi-language project

**User**: "Create gitignore"

**Detected files:**
- `package.json` (Node.js)
- `requirements.txt` (Python)

**Expected behavior:**

Create `.gitignore` with both Node.js and Python patterns:

```gitignore
# Dependencies - Node.js
node_modules/

# Dependencies - Python
venv/
.venv/
env/

# Build outputs
dist/
build/

# Python bytecode
__pycache__/
*.py[cod]
*.so

# Environment variables
.env
.env.local

# Logs
*.log

# OS-specific
.DS_Store
Thumbs.db

# IDE/Editor
.vscode/
.idea/
*.swp

# Testing
coverage/
.pytest_cache/
htmlcov/
```

Report: "Created .gitignore for Node.js and Python project"

### Example 4: Tracked files that should be ignored

**User**: "Update gitignore"

**After updating .gitignore:**

```bash
# Check for tracked files matching .gitignore patterns
git ls-files -ci --exclude-standard
```

**Output:**
```
.env
debug.log
```

**Report to user:**

```
Updated .gitignore successfully.

⚠️  Warning: The following tracked files match .gitignore patterns:
- .env
- debug.log

To remove them from git tracking (keeps local files):
  git rm --cached .env debug.log
  git commit -m "chore: remove ignored files from tracking"
```

## Edge Cases

### No Project Type Detected

If no clear project type is found:
- Ask user: "What type of project is this? (node/python/rust/go/java/ruby/other)"
- Or create generic .gitignore with common patterns:

```gitignore
# Build outputs
dist/
build/
target/
out/

# Dependencies
node_modules/
vendor/

# Environment variables
.env
.env.local

# Logs
*.log
logs/

# OS-specific
.DS_Store
Thumbs.db
desktop.ini

# IDE/Editor
.vscode/
.idea/
.fleet/
*.swp
*.swo
*~

# Cache
.cache/

# Temporary files
tmp/
temp/
*.tmp
```

### .gitignore Already Comprehensive

If existing `.gitignore` already covers all necessary patterns:
- Report: "Your .gitignore is already comprehensive, no updates needed"
- Do not make changes

### Multiple Project Types

If multiple project types detected:
- Include patterns for all detected types
- Group by language/framework
- Add comment headers for each section

### Very Large .gitignore

If existing `.gitignore` is very large (>200 lines):
- Ask: "Your .gitignore is quite large. Audit and simplify it? (yes/no)"
- If yes, remove duplicates and overly broad patterns

### Binary or Generated Files Tracked

If large binaries or generated files are tracked:
- Warn: "Found large or generated files in git history"
- Suggest: "Consider using BFG Repo-Cleaner to remove from history"
- Add patterns to prevent future tracking

## Guidelines

1. **Start minimal** - add patterns as needed, don't pre-emptively ignore everything
2. **Keep it organized** - use comments to group related patterns
3. **Be specific** - `*.log` is better than `*` in most cases
4. **Never ignore source code** - only generated files and dependencies
5. **Check what's tracked** - use `git ls-files -ci --exclude-standard` after updating
6. **Preserve custom patterns** - respect user's existing additions
7. **Use standard templates** - leverage community-maintained patterns
8. **Document unusual patterns** - add comments explaining non-obvious ignores
9. **Test the patterns** - verify they work as expected
10. **Consider .gitignore_global** - suggest OS/editor patterns for user's global config

## Anti-Patterns to Avoid

❌ **DO NOT**:
- Ignore entire directories without understanding them
- Use overly broad patterns like `*.json` or `*.yaml`
- Ignore configuration files that should be versioned
- Ignore source code or documentation
- Create massive .gitignore files with unused patterns
- Remove custom user patterns when updating

✅ **DO**:
- Detect project type before adding patterns
- Preserve custom entries in existing .gitignore
- Organize patterns into logical sections
- Add comments for clarity
- Check for tracked files that should be ignored
- Use standard, community-vetted patterns

## References

- [github/gitignore](https://github.com/github/gitignore) - Collection of useful .gitignore templates
- [Git Documentation - gitignore](https://git-scm.com/docs/gitignore)
