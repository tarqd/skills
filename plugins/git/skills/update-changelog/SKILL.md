---
name: update-changelog
description: Analyze git changes and update CHANGELOG.md with new features, fixes, breaking changes, and other relevant entries following Keep a Changelog format
user-invokable: true
context: fork
agent: Explore
---

# Changelog Updater

Intelligently analyze git changes since the last CHANGELOG update and add appropriate entries following the Keep a Changelog format.

## Prerequisites

- Git CLI installed and available in PATH
- Current working directory must be in a git repository
- Git history available

## Core Principles

- **Follow Keep a Changelog format** - standard, widely-used changelog format
- **Group by change type** - Added, Changed, Deprecated, Removed, Fixed, Security
- **Focus on user-facing changes** - what affects users, not internal details
- **Be concise and clear** - one line per change, actionable descriptions
- **Use Unreleased section** - for changes not yet in a tagged release
- **Preserve existing entries** - never modify past releases
- **Link to commits/PRs** - provide references when helpful
- **Semantic versioning** - follow semver for version numbers

## Keep a Changelog Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature descriptions

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes and improvements

## [1.0.0] - 2024-01-30

### Added
- Initial release
```

## Change Categories

### Added
New features or capabilities that users can now use.

**Examples:**
- Added user authentication with JWT
- Added dark mode support
- Added export to CSV functionality
- Added `--verbose` flag to CLI

### Changed
Changes to existing functionality that alter behavior but don't break compatibility.

**Examples:**
- Changed default timeout from 30s to 60s
- Updated error messages to be more descriptive
- Improved performance of search algorithm
- Changed button color for better accessibility

### Deprecated
Features that still work but will be removed in a future version.

**Examples:**
- Deprecated `getUser()` in favor of `fetchUser()`
- Deprecated XML configuration format (use YAML instead)
- Deprecated `--old-flag` CLI option

### Removed
Features or functionality that have been removed (breaking change).

**Examples:**
- Removed deprecated `oldMethod()` function
- Removed support for Node.js 12
- Removed legacy API v1 endpoints

### Fixed
Bug fixes that restore intended functionality.

**Examples:**
- Fixed crash when parsing empty responses
- Fixed memory leak in WebSocket connections
- Fixed incorrect calculation in tax function
- Fixed typo in error message

### Security
Security fixes, vulnerability patches, or security-related improvements.

**Examples:**
- Fixed SQL injection vulnerability in search
- Updated dependencies to patch CVE-2024-1234
- Added rate limiting to prevent brute force attacks
- Improved password hashing algorithm

## Workflow Steps

### 1. Check if CHANGELOG.md Exists

```bash
# Check for CHANGELOG.md
ls -la CHANGELOG.md 2>/dev/null

# Also check common alternatives
ls -la CHANGELOG 2>/dev/null
ls -la HISTORY.md 2>/dev/null
```

If no changelog exists:
- Ask: "No CHANGELOG.md found. Create one? (yes/no)"
- If yes, create initial changelog structure

### 2. Find Changes Since Last CHANGELOG Update

```bash
# Get the last commit that modified CHANGELOG
LAST_UPDATE=$(git log -n1 --format=%H -- CHANGELOG.md 2>/dev/null)

# If CHANGELOG never updated, use first commit
if [ -z "$LAST_UPDATE" ]; then
  LAST_UPDATE=$(git rev-list --max-parents=0 HEAD)
fi

# Get commits since last update
git log --oneline "$LAST_UPDATE..HEAD"

# Get detailed changes
git log --format="%h %s" "$LAST_UPDATE..HEAD"
```

### 3. Analyze Commits and Categorize

For each commit since last CHANGELOG update:

1. **Parse commit message** - look for Conventional Commits format
2. **Categorize by type**:
   - `feat:` → Added
   - `fix:` → Fixed
   - `refactor:`, `perf:`, `style:` → Changed (if user-facing)
   - `security:` → Security
   - `BREAKING CHANGE:` → Removed or Changed (with warning)
   - `deprecated:` → Deprecated
   - `test:`, `chore:`, `ci:`, `build:` → Skip (internal)

3. **Filter user-facing changes**:
   - ✅ Include: features, fixes, breaking changes, API changes, config changes
   - ❌ Skip: internal refactors, test changes, CI updates, dependency bumps (unless security-related)

4. **Extract descriptions**:
   - Use commit subject line as base
   - Remove type prefix (`feat:`, `fix:`, etc.)
   - Remove scope if not relevant to users
   - Make it user-facing and actionable

### 4. Read Current CHANGELOG

```bash
# Read existing CHANGELOG
cat CHANGELOG.md
```

Identify:
- Current format (Keep a Changelog, custom, etc.)
- Latest version number
- Structure of Unreleased section
- Existing entries to avoid duplicates

### 5. Build New Entries

Group changes by category:

```markdown
## [Unreleased]

### Added
- New authentication system with OAuth support
- Export functionality for reports (CSV and PDF)
- Dark mode toggle in user settings

### Changed
- Improved search performance by 50%
- Updated error messages for clarity

### Fixed
- Fixed crash when uploading large files
- Fixed incorrect date display in timezone UTC-12
- Fixed memory leak in background workers

### Security
- Updated dependencies to patch vulnerabilities
```

**Guidelines for entries:**
- One line per change
- Start with verb (Added, Fixed, Updated, etc.)
- Be specific but concise
- Focus on user impact, not implementation
- Include references to PRs/issues if helpful: `(#123)`
- Group related changes together

### 6. Update CHANGELOG

**If using Keep a Changelog format:**

1. Find or create `## [Unreleased]` section
2. Add entries under appropriate category headings
3. Preserve existing Unreleased entries
4. Maintain alphabetical or chronological order within categories

**If using custom format:**

1. Follow the existing pattern
2. Add entries in the appropriate location
3. Maintain consistency with existing style

### 7. Verify and Report

```bash
# Show the updated section
head -50 CHANGELOG.md
```

Report:
- How many entries were added
- Which categories were updated
- Summary of changes

## Examples

### Example 1: New feature and bug fix

**User**: "Update the changelog"

**After analysis:**

Commits since last update:
```
a1b2c3d feat(auth): add OAuth authentication
e4f5g6h fix(upload): handle large file uploads correctly
i7j8k9l chore(deps): update eslint to v8
```

**Categorization:**
- `feat(auth): add OAuth authentication` → Added
- `fix(upload): handle large file uploads correctly` → Fixed
- `chore(deps): update eslint to v8` → Skip (internal)

**Update CHANGELOG:**

```markdown
## [Unreleased]

### Added
- OAuth authentication support (Google, GitHub, and Microsoft)

### Fixed
- Fixed crash when uploading files larger than 100MB
```

**Report:**
```
Updated CHANGELOG.md with 2 entries:
- Added: 1 entry
- Fixed: 1 entry
```

### Example 2: Breaking change

**User**: "Update changelog"

**After analysis:**

Commits:
```
a1b2c3d feat!: change API response format to REST standard
e4f5g6h docs: update API documentation
```

**Categorization:**
- `feat!: change API response format` → Changed (breaking)
- `docs: update API documentation` → Skip

**Update CHANGELOG:**

```markdown
## [Unreleased]

### Changed
- **BREAKING**: Changed API response format to follow REST standards. Responses now use `data`, `error`, and `meta` fields. See migration guide in docs/migration.md
```

**Report:**
```
Updated CHANGELOG.md with 1 breaking change:
- Changed: API response format (breaking change)

⚠️  Remember to update version number when releasing (major version bump for breaking changes)
```

### Example 3: No relevant changes

**User**: "Update changelog"

**After analysis:**

Commits:
```
a1b2c3d test: add unit tests for parser
e4f5g6h refactor: extract validation logic
i7j8k9l ci: update GitHub Actions workflow
```

**Categorization:**
- All commits are internal (tests, refactor, CI)
- No user-facing changes

**Report:**
```
No changelog updates needed. Changes since last update:
- Internal refactoring
- Test additions
- CI configuration updates

None of these require changelog entries.
```

### Example 4: Create new CHANGELOG

**User**: "yes" (after being asked about creating CHANGELOG)

**Actions:**

1. Get recent commits to populate initial entries:

```bash
git log --format="%h %s" --max-count=20
```

2. Create CHANGELOG.md with structure:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup
- User authentication system
- Dashboard with analytics
- REST API endpoints

### Fixed
- Various bug fixes and improvements
```

**Report:**
```
Created CHANGELOG.md with Keep a Changelog format.
Added initial entries based on recent commits.
```

### Example 5: Multiple categories

**User**: "Update changelog"

**After analysis:**

Commits:
```
a1b2c3d feat(search): add full-text search
e4f5g6h feat(export): add PDF export
i7j8k9l fix(auth): prevent token expiry race condition
m1n2o3p security: update dependencies to patch CVE-2024-1234
q4r5s6t deprecated: mark v1 API as deprecated
```

**Update CHANGELOG:**

```markdown
## [Unreleased]

### Added
- Full-text search across all content
- PDF export functionality for reports

### Deprecated
- API v1 endpoints (use v2 instead, v1 will be removed in next major version)

### Fixed
- Fixed race condition in token refresh causing intermittent 401 errors

### Security
- Updated dependencies to patch CVE-2024-1234 (high severity)
```

**Report:**
```
Updated CHANGELOG.md with 5 entries:
- Added: 2 entries
- Deprecated: 1 entry
- Fixed: 1 entry
- Security: 1 entry
```

## Edge Cases

### CHANGELOG Doesn't Exist

If no CHANGELOG.md found:
- Inform user
- Ask: "Would you like to create a CHANGELOG.md? (yes/no)"
- If yes, create with Keep a Changelog format
- Populate with recent significant changes

### No Changes Since Last Update

If CHANGELOG was just updated:
- Report: "CHANGELOG is up to date, no new entries needed"
- Do not make unnecessary updates

### Custom Changelog Format

If existing CHANGELOG doesn't follow Keep a Changelog:
- Detect the format used
- Ask: "Should I convert to Keep a Changelog format? (yes/convert/keep current)"
- If "keep current", follow existing pattern
- If "convert", convert existing entries

### Version Release

If user is preparing a release:
- Ask: "What version number for this release? (e.g., 1.2.0)"
- Move Unreleased entries to new version section
- Add release date
- Add comparison links at bottom

```markdown
## [1.2.0] - 2024-01-30

### Added
- New features...

[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
```

### Duplicate Entries

If similar entry already exists in Unreleased:
- Skip the duplicate
- Report: "Skipped 1 duplicate entry"

### Very Long Descriptions

If commit message is very long:
- Summarize to one line
- Extract the key user-facing change
- Add reference to commit: `(abc1234)`

### Merge Commits

If analyzing merge commits:
- Skip generic merge commit messages
- Look at the individual commits in the merge
- Extract meaningful changes only

## Guidelines

1. **Follow Keep a Changelog format** - industry standard
2. **Focus on user-facing changes** - skip internal refactors
3. **Be concise** - one line per change
4. **Use clear language** - avoid technical jargon when possible
5. **Group by category** - Added, Changed, Deprecated, Removed, Fixed, Security
6. **Preserve history** - never modify past release entries
7. **Add to Unreleased** - until a version is released
8. **Reference PRs/issues** - when relevant: `(#123)`
9. **Highlight breaking changes** - prefix with **BREAKING**
10. **Keep it up to date** - update with each significant change

## Anti-Patterns to Avoid

❌ **DO NOT**:
- Add internal changes (refactors, test updates, CI)
- Duplicate entries already in CHANGELOG
- Modify past release entries
- Use vague descriptions ("various fixes")
- Include commit hashes as the main description
- Add every single commit
- Use technical jargon unnecessarily

✅ **DO**:
- Focus on user-facing changes
- Write clear, actionable descriptions
- Group related changes together
- Follow Keep a Changelog categories
- Be concise but informative
- Add references to PRs/issues when helpful
- Highlight breaking changes clearly

## References

- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
