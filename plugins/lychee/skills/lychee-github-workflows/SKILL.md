---
name: Lychee GitHub Workflows
description: This skill should be used when the user asks to "create GitHub workflow for lychee", "set up link checking in CI", "automate link validation", "add link check to PR", or "schedule link checking" in GitHub Actions.
version: 0.1.0
---

# Lychee GitHub Workflows

## Overview

Automate link checking using GitHub Actions with lychee. Create workflows for pull request validation and scheduled checks to catch broken links before they reach production.

## Workflow Types

### PR Link Check

Check links in pull requests before merging:

**Benefits:**
- Catch broken links during code review
- Prevent broken links from reaching main branch
- Provide immediate feedback to contributors

**Use `lycheeverse/lychee-action`** for GitHub Actions integration.

### Scheduled Link Check

Periodically check links on main branch:

**Benefits:**
- Detect links that break over time
- Regular health checks for documentation
- Automated issue creation for broken links

## PR Link Check Workflow

Create `.github/workflows/pr-linkcheck.yml`:

```yaml
name: PR Link Check

on:
  pull_request:
    branches:
      - main

jobs:
  linkcheck:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout PR branch
        uses: actions/checkout@v5

      - name: Restore lychee cache
        uses: actions/cache@v4
        with:
          path: .lycheecache
          key: cache-lychee-${{ github.sha }}
          restore-keys: cache-lychee-

      - name: Link Check
        uses: lycheeverse/lychee-action@v2
        with:
          args: --config lychee.toml --cache '**/*.md' '**/*.html'
          output: .lychee.report.md

      - name: Comment Broken Links
        uses: marocchino/sticky-pull-request-comment@v2
        if: failure()
        with:
          path: .lychee.report.md
```

**Key features:**
- Triggers on PR to main branch
- Uses cache for faster checks
- Posts report as PR comment
- Only comments if broken links found

See `examples/pr-linkcheck.yml` for complete workflow.

## Scheduled Link Check Workflow

Create `.github/workflows/scheduled-linkcheck.yml`:

```yaml
name: Scheduled Link Check

on:
  schedule:
    - cron: "0 18 * * *"  # Daily at 6 PM UTC
  workflow_dispatch:      # Allow manual triggers

jobs:
  linkcheck:
    runs-on: ubuntu-latest
    permissions:
      issues: write
    steps:
      - name: Checkout main branch
        uses: actions/checkout@v5

      - name: Restore lychee cache
        uses: actions/cache@v4
        with:
          path: .lycheecache
          key: cache-lychee-${{ github.sha }}
          restore-keys: cache-lychee-

      - name: Link Check
        id: lychee
        uses: lycheeverse/lychee-action@v2
        with:
          args: --config lychee.toml --cache '**/*.md'
          fail: false
          output: .lychee.report.md

      - name: Create Issue
        if: steps.lychee.outputs.exit_code != 0
        uses: peter-evans/create-issue-from-file@v5
        with:
          title: Link Checker Report
          content-filepath: .lychee.report.md
          labels: report, automated issue
```

**Key features:**
- Runs daily (configurable schedule)
- Manual trigger available via `workflow_dispatch`
- Creates GitHub issue if broken links found
- Uses cache for efficiency
- Non-blocking (`fail: false`)

See `examples/scheduled-linkcheck.yml` for complete workflow.

## Lychee Action Configuration

### Basic Options

```yaml
- uses: lycheeverse/lychee-action@v2
  with:
    args: '--config lychee.toml --cache docs/'
    output: report.md
    fail: true
```

### All Options

```yaml
- uses: lycheeverse/lychee-action@v2
  with:
    # Arguments passed to lychee
    args: |
      --config lychee.toml
      --cache
      --max-concurrency 10
      --exclude 'example\.com'
      '**/*.md'

    # Output file for report
    output: .lychee.report.md

    # Fail workflow on broken links
    fail: true

    # GitHub token for API access
    token: ${{ secrets.GITHUB_TOKEN }}

    # Lychee version (default: latest)
    version: latest
```

## Caching Strategy

Cache lychee results to speed up checks and reduce server load:

```yaml
- name: Restore lychee cache
  uses: actions/cache@v4
  with:
    path: .lycheecache
    key: cache-lychee-${{ github.sha }}
    restore-keys: |
      cache-lychee-${{ github.ref }}
      cache-lychee-
```

**Cache key strategies:**

1. **Per-commit** (strictest): `cache-lychee-${{ github.sha }}`
2. **Per-branch**: `cache-lychee-${{ github.ref }}`
3. **Global** (fastest): `cache-lychee-`

**Recommendation:** Use global cache with restore-keys for balance between speed and freshness.

## Advanced Workflows

### Check Only Changed Files

Check only files modified in PR:

```yaml
- name: Get changed files
  id: changed-files
  uses: tj-actions/changed-files@v44
  with:
    files: |
      **/*.md
      **/*.html

- name: Link Check Changed Files
  if: steps.changed-files.outputs.any_changed == 'true'
  uses: lycheeverse/lychee-action@v2
  with:
    args: --cache ${{ steps.changed-files.outputs.all_changed_files }}
```

**Benefits:** Faster PR checks, only validate what changed.

### Check Built Documentation

For projects that generate documentation:

```yaml
- name: Build documentation
  run: |
    npm run build
    # or: mdbook build
    # or: mkdocs build

- name: Link Check Built Site
  uses: lycheeverse/lychee-action@v2
  with:
    args: |
      --config lychee.toml
      --root-dir $(pwd)/dist
      --base-url https://example.com
      --cache
      dist/
```

**Use case:** Check generated HTML after build process.

### Matrix Testing

Test against multiple configurations:

```yaml
strategy:
  matrix:
    config: [lenient.toml, strict.toml]
jobs:
  linkcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: lycheeverse/lychee-action@v2
        with:
          args: --config ${{ matrix.config }} docs/
```

**Use case:** Different strictness levels for different branches.

## Environment Variables

### GitHub Token

Avoid rate limiting on GitHub URLs:

```yaml
- name: Link Check
  uses: lycheeverse/lychee-action@v2
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    args: --cache docs/
```

**Automatic:** lychee-action sets `GITHUB_TOKEN` by default.

### Custom Variables

Pass custom environment variables:

```yaml
- name: Link Check
  uses: lycheeverse/lychee-action@v2
  env:
    CUSTOM_VAR: value
  with:
    args: --cache docs/
```

## Workflow Triggers

### On Pull Request

```yaml
on:
  pull_request:
    branches: [main, develop]
    paths:
      - '**/*.md'
      - '**/*.html'
      - 'lychee.toml'
```

**Optimization:** Only trigger on relevant file changes.

### On Push

```yaml
on:
  push:
    branches: [main]
```

### On Schedule

```yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday at midnight
    - cron: '0 18 * * *' # Daily at 6 PM UTC
```

**Cron syntax:** `minute hour day month weekday`

### Manual Trigger

```yaml
on:
  workflow_dispatch:
    inputs:
      target:
        description: 'Directory to check'
        required: false
        default: 'docs/'
```

**Usage:** Run workflow manually from GitHub Actions tab.

### Multiple Triggers

```yaml
on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 18 * * *'
  workflow_dispatch:
```

## Output Handling

### PR Comments

Post results as PR comment:

```yaml
- name: Comment Results
  uses: marocchino/sticky-pull-request-comment@v2
  if: always()  # Comment even if check passes
  with:
    path: .lychee.report.md
    header: link-check-report
```

**`header` parameter:** Updates existing comment instead of creating new ones.

### Create Issues

Create issue for broken links:

```yaml
- name: Create Issue
  if: steps.lychee.outputs.exit_code != 0
  uses: peter-evans/create-issue-from-file@v5
  with:
    title: 'Broken Links Found - ${{ github.run_id }}'
    content-filepath: .lychee.report.md
    labels: bug, documentation, automated
    assignees: '@username'
```

### Upload Artifacts

Save report as workflow artifact:

```yaml
- name: Upload Report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: lychee-report
    path: .lychee.report.md
```

## Integration Patterns

### With Documentation Sites

**MkDocs:**
```yaml
- run: mkdocs build
- uses: lycheeverse/lychee-action@v2
  with:
    args: --root-dir $(pwd)/site site/
```

**mdBook:**
```yaml
- run: mdbook build
- uses: lycheeverse/lychee-action@v2
  with:
    args: --root-dir $(pwd)/book book/
```

**Docusaurus:**
```yaml
- run: npm run build
- uses: lycheeverse/lychee-action@v2
  with:
    args: --root-dir $(pwd)/build build/
```

### With Remap for Local Builds

Check locally built site with production URL references:

```yaml
- name: Build site
  run: npm run build

- name: Link Check with Remap
  uses: lycheeverse/lychee-action@v2
  with:
    args: |
      --root-dir $(pwd)/dist
      --remap 'https://example.com file://$(pwd)/dist'
      --cache
      dist/
```

## Best Practices

1. **Use caching** to speed up checks and reduce external load
2. **Set appropriate concurrency** to avoid overwhelming servers
3. **Accept 429 status** codes to handle rate limiting gracefully
4. **Use fail: false** for scheduled checks to avoid noise
5. **Add workflow_dispatch** for manual testing
6. **Cache globally** with restore-keys for balance
7. **Check built sites** not source files when generating documentation
8. **Use GitHub token** to avoid API rate limits
9. **Filter triggers** to only run on relevant file changes
10. **Comment on PRs** to provide immediate feedback

## Troubleshooting

### Workflow Fails with Rate Limiting

**Solution:** Use caching and GitHub token:

```yaml
- uses: lycheeverse/lychee-action@v2
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    args: --cache --accept '200..=299,429' docs/
```

### Cache Not Working

**Solution:** Ensure cache path matches lychee cache location:

```yaml
with:
  path: .lycheecache  # Must match lychee's cache directory
```

### Workflow Too Slow

**Solutions:**
1. Enable caching
2. Reduce concurrency: `--max-concurrency 10`
3. Check only changed files
4. Increase cache age: `--max-cache-age 7d`

### False Positives

**Solution:** Configure exclusions in `lychee.toml`:

```toml
exclude = [
  "https://example\\.com",
  "localhost"
]
```

## Additional Resources

### Example Files

Complete workflow examples in `examples/`:

- **`examples/pr-linkcheck.yml`** - PR link check with PR comments
- **`examples/scheduled-linkcheck.yml`** - Scheduled checks with issue creation
- **`examples/mdbook-workflow.yml`** - Complete mdBook project workflow

### Related Skills

- **installing-lychee** - Installing lychee locally
- **using-lychee** - Running lychee CLI
- **configuring-lychee** - Creating lychee.toml configuration

### External Resources

- **lychee-action**: https://github.com/lycheeverse/lychee-action
- **GitHub Actions docs**: https://docs.github.com/actions
- **Cron schedule**: https://crontab.guru

## Next Steps

1. Create `lychee.toml` configuration file
2. Add PR link check workflow
3. Test workflow with draft PR
4. Add scheduled check workflow
5. Configure issue labels and assignees
6. Enable workflow caching
7. Document workflow in repository README
