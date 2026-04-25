---
name: Configuring Lychee
description: This skill should be used when the user asks to "create lychee.toml", "configure lychee", "set up lychee config", "customize link checking", "exclude URLs from lychee", or needs to configure lychee link checking behavior.
version: 0.1.0
---

# Configuring Lychee

## Overview

Configure lychee behavior using `lychee.toml` files. Configuration files provide persistent settings for link checking, avoiding repetitive CLI flags and ensuring consistent checks across team members.

## Configuration File Location

Lychee automatically searches for `lychee.toml` in:

1. Current working directory
2. Parent directories (walks up the tree)

**Custom location:**

```bash
lychee --config path/to/custom.toml docs/
```

## Basic Configuration Structure

```toml
# lychee.toml

# Cache settings
cache = true
max_cache_age = "1d"

# Request behavior
timeout = 30
max_retries = 3
max_concurrency = 128

# Status code handling
accept = [200, 201, 202, 203, 204, 429]

# URL patterns
exclude = [
  "https://example.com",
  "localhost",
  "127\\.0\\.0\\.1"
]
```

## Common Configuration Options

### Caching

```toml
# Enable cache
cache = true

# Cache age (e.g., "1d", "2h", "30m")
max_cache_age = "1d"

# Exclude status codes from cache
cache_exclude_status = [429, 500]
```

### Request Settings

```toml
# Timeout in seconds
timeout = 30

# Maximum redirects to follow
max_redirects = 5

# Retry configuration
max_retries = 3
retry_wait_time = 2

# Concurrency
max_concurrency = 128
```

### Accepted Status Codes

```toml
# Accept specific codes
accept = [200, 201, 202, 203, 204, 429]

# Or use ranges (in CLI only, not TOML)
# --accept '200..=299,429'
```

**Note:** TOML format requires array notation, not ranges.

### URL Exclusions

```toml
# Exclude URL patterns (regex)
exclude = [
  "https://example\\.com/.*",
  "localhost",
  "127\\.0\\.0\\.1",
  "^https://github\\.com/.*/edit/.*",
  ".*\\.example\\.org"
]

# Exclude file paths (regex)
exclude_path = [
  "node_modules/.*",
  "target/.*",
  "\\.git/.*"
]
```

### URL Inclusions

```toml
# Check only matching patterns
include = [
  "^https://mysite\\.com/.*"
]
```

**Note:** Include patterns override excludes.

### Scheme Filtering

```toml
# Check only specific schemes
scheme = ["https"]

# Require HTTPS when available
require_https = true
```

### User Agent

```toml
# Custom user agent
user_agent = "Mozilla/5.0 (compatible; MyBot/1.0)"
```

### Headers

```toml
# Custom headers for requests
headers = [
  "Accept: text/html",
  "Authorization: Bearer token123"
]
```

## Advanced Configuration

### Remapping URLs

```toml
# Remap production URLs to local paths
[[remap]]
pattern = "https://example.com"
replacement = "file:///path/to/project/build"
```

**Use case:** Check locally built sites that reference production URLs.

### Base URL

```toml
# Resolve relative links as if hosted at base URL
base_url = "https://example.com/docs/"
```

### Root Directory

```toml
# Resolve absolute links in local files
root_dir = "/path/to/build"
```

### Include/Exclude Options

```toml
# Include verbatim sections
include_verbatim = true

# Include fragments (#anchors)
include_fragments = true

# Include email addresses
include_mail = true

# Skip hidden files
hidden = false
```

### GitHub Token

```toml
# GitHub API token (or use environment variable)
# github_token = "ghp_..." # Better: use GITHUB_TOKEN env var
```

**Recommendation:** Using environment variable `GITHUB_TOKEN` is preferred over hardcoding tokens.

## Configuration Examples

### Documentation Site

```toml
# lychee.toml - Documentation project

cache = true
max_cache_age = "7d"

timeout = 30
max_retries = 3
max_concurrency = 100

accept = [200, 201, 202, 203, 204, 429]

exclude = [
  "localhost",
  "127\\.0\\.0\\.1",
  "https://example\\.com",  # Placeholder URLs
  "https://.*\\.example\\.org"
]

exclude_path = [
  "node_modules/.*",
  "dist/.*",
  "\\.git/.*"
]

include_verbatim = false
```

See `examples/docs-site.toml` for complete example.

### mdBook Project

```toml
# lychee.toml - mdBook configuration

cache = true
max_cache_age = "1d"

timeout = 20
max_retries = 5

accept = [200, 201, 202, 203, 204, 429]

# Common mdBook build artifacts to exclude
exclude_path = [
  "book/.*",
  "node_modules/.*"
]

exclude = [
  "localhost",
  "127\\.0\\.0\\.1"
]

# Check source files, not generated HTML
# Run: lychee --config lychee.toml src/
```

See `examples/mdbook.toml` for complete example.

### GitHub Repository

```toml
# lychee.toml - GitHub repository

cache = true
max_cache_age = "1d"

timeout = 30
accept = [200, 201, 202, 203, 204, 429]

exclude = [
  # Exclude edit URLs (requires auth)
  "^https://github\\.com/.*/edit/.*",

  # Exclude local development
  "localhost",
  "127\\.0\\.0\\.1",

  # Placeholder domains
  "example\\.com"
]

exclude_path = [
  "node_modules/.*",
  "target/.*",
  "vendor/.*",
  "\\.git/.*"
]
```

See `examples/github-repo.toml` for complete example.

### Strict Configuration

```toml
# lychee.toml - Strict checking for production

cache = false  # Always check fresh
timeout = 60
max_retries = 5

# Only accept success codes
accept = [200, 201, 202, 203, 204]

# Require HTTPS
require_https = true
scheme = ["https"]

# Check everything
include_verbatim = true
include_fragments = true
include_mail = true

exclude = []  # Check all links
```

See `examples/strict.toml` for complete example.

## Working with Remap Patterns

Remap allows checking locally built sites with production URLs:

```toml
[[remap]]
pattern = "https://example.com"
replacement = "file:///path/to/project/build"

[[remap]]
pattern = "https://cdn.example.com"
replacement = "file:///path/to/project/assets"
```

**Multiple remaps:** Use multiple `[[remap]]` sections.

**Workflow:**
1. Build documentation site locally
2. Configure remap from production URLs to local paths
3. Run lychee with `--root-dir` pointing to build directory
4. Lychee checks local files instead of hitting production

**Example from field-guide project:**

```bash
lychee --config lychee.toml \
  --root-dir "$(pwd)/book/html/" \
  --remap "https://example.com file://$(pwd)/book/html" \
  book/html
```

## Validation

Test configuration before committing:

```bash
# Dry run to see what would be checked
lychee --dump README.md

# See all inputs that would be processed
lychee --dump-inputs '**/*.md'

# Verbose output to verify settings
lychee --verbose README.md
```

## Configuration Precedence

Settings priority (highest to lowest):

1. Command-line flags
2. `lychee.toml` configuration file
3. Default values

**Example:** If `lychee.toml` sets `timeout = 30` but CLI uses `--timeout 60`, the CLI value (60) takes precedence.

## Additional Resources

### Example Files

Complete configuration examples in `examples/`:

- **`examples/docs-site.toml`** - Documentation project configuration
- **`examples/mdbook.toml`** - mdBook-specific configuration
- **`examples/github-repo.toml`** - GitHub repository configuration
- **`examples/strict.toml`** - Strict production checking

### Related Skills

- **using-lychee** - Running lychee CLI commands
- **lychee-github-workflows** - GitHub Actions integration

## Best Practices

1. **Commit lychee.toml** to version control for consistency
2. **Use caching** for faster repeated checks
3. **Accept 429** status codes to handle rate limiting gracefully
4. **Exclude known issues** temporarily while fixing
5. **Use environment variables** for secrets (GITHUB_TOKEN)
6. **Document exclusions** with comments explaining why
7. **Test configuration** with `--dump` before running full checks

## Common Patterns

### Temporary Exclusions

Add comments for temporary exclusions:

```toml
exclude = [
  # TODO: Fix broken links (Issue #123)
  "https://oldsite\\.example\\.com/.*",

  # Temporarily down (2024-01-15)
  "https://partner-api\\.example\\.org"
]
```

### Environment-Specific Configuration

Use different configs for different environments:

```bash
# Local development (lenient)
lychee --config lychee.dev.toml docs/

# CI/Production (strict)
lychee --config lychee.prod.toml docs/
```

### Incremental Strictness

Start lenient, gradually tighten:

```toml
# Phase 1: Basic checking
accept = [200, 201, 202, 203, 204, 429, 500, 502, 503]
exclude = ["lots", "of", "patterns"]

# Phase 2: After fixing obvious issues
accept = [200, 201, 202, 203, 204, 429]
exclude = ["fewer", "patterns"]

# Phase 3: Strict (production ready)
accept = [200, 201, 202, 203, 204]
exclude = []
```

## Next Steps

1. Create `lychee.toml` in project root
2. Test configuration with small file set
3. Adjust exclusions based on results
4. Commit configuration to version control
5. Set up GitHub Actions workflow (see `lychee-github-workflows` skill)
