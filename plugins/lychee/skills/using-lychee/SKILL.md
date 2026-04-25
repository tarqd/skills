---
name: Using Lychee
description: This skill should be used when the user asks to "check links", "run lychee", "validate links", "find broken links", "check URLs in markdown", "check URLs in HTML", or wants to use lychee to check links in documentation or files.
version: 0.1.0
---

# Using Lychee

## Overview

Lychee is a fast, asynchronous link checker for markdown, HTML, and plain text files. Use it to validate links in documentation, find broken URLs, and maintain link health in projects.

## Basic Usage

### Check Single File

```bash
lychee README.md
```

### Check Multiple Files

```bash
lychee README.md CONTRIBUTING.md docs/
```

### Check with Glob Patterns

```bash
lychee '**/*.md'
lychee 'docs/**/*.{md,html}'
```

**Important:** Quote glob patterns to prevent shell expansion.

### Check URLs Directly

```bash
lychee https://example.com
lychee https://example.com/docs/
```

## Common Options

### Caching for Performance

Enable caching to skip re-checking previously validated links:

```bash
lychee --cache README.md
```

**Cache location:** `.lycheecache/` directory (add to .gitignore)

**Benefits:**
- Faster subsequent runs
- Reduces load on remote servers
- Configurable cache age with `--max-cache-age`

### Timeout and Retries

Control request behavior:

```bash
# Set timeout (default: 20s)
lychee --timeout 30 docs/

# Configure retries (default: 3)
lychee --max-retries 5 README.md

# Wait time between retries (default: 1s)
lychee --retry-wait-time 2 docs/
```

### Accept Specific Status Codes

Accept status codes beyond the default 2xx range:

```bash
# Accept 429 (Too Many Requests)
lychee --accept '200..=299,429' README.md

# Accept range including specific codes
lychee --accept '100..=103,200..=299,429,500' docs/
```

**Default accepted codes:** `100..=103,200..=299`

### Exclude Patterns

Exclude URLs matching regex patterns:

```bash
# Exclude specific domain
lychee --exclude 'example\.com' README.md

# Exclude multiple patterns
lychee --exclude 'localhost|127\.0\.0\.1|example\.com' docs/

# Exclude URL paths
lychee --exclude '/draft/|/wip/' docs/
```

### Include Only Specific URLs

Check only URLs matching patterns:

```bash
# Check only HTTPS links
lychee --include 'https://.*' README.md

# Check specific domain only
lychee --include 'https://mysite\.com/.*' docs/
```

**Note:** Include patterns take precedence over exclude patterns.

## Output Formats

### Compact (Default)

```bash
lychee README.md
```

Shows summary with broken links.

### Detailed

```bash
lychee --format detailed README.md
```

Shows all links checked with status codes.

### JSON

```bash
lychee --format json README.md > report.json
```

Machine-readable output for automation.

### Markdown

```bash
lychee --format markdown README.md > report.md
```

GitHub-friendly markdown report.

## Working with Local Files

### Base URL for Relative Links

Resolve relative links as if files were hosted at a base URL:

```bash
lychee --base-url https://example.com/docs/ README.md
```

**Example:**
- File contains link: `../api/reference.html`
- Base URL: `https://example.com/docs/guide/`
- Resolves to: `https://example.com/docs/api/reference.html`

### Root Directory for Absolute Links

Resolve absolute links in local files:

```bash
lychee --root-dir $(pwd)/build /page.html
```

**Use case:** Checking generated static sites with absolute paths.

### Combining Base URL and Root Directory

```bash
lychee --base-url https://example.com --root-dir $(pwd)/public docs/
```

Constructs URLs from: domain + root-dir + absolute-path.

## Advanced Features

### Remap URLs

Remap production URLs to local paths for testing:

```bash
lychee --remap 'https://example.com file:///$(pwd)/build' docs/
```

**Use case:** Check links in locally built documentation that reference production URLs.

### Preprocessing Files

**IMPORTANT:** Only use `--preprocess` when explicitly instructed by the user.

Preprocess files into supported formats before checking:

```bash
# Example: Convert PDFs to HTML before checking
lychee --preprocess 'pdftohtml -i -s -noframes {} {}.html' docs/*.pdf
```

**Format placeholders:**
- `{}` - Input file path
- `{}.html` - Output file path (lychee will check this)

**Common preprocessors:**
- `pdftohtml` - PDF to HTML
- `pandoc` - Various formats to HTML/Markdown
- Custom scripts for proprietary formats

**Requirement:** Preprocessor must be installed and accessible.

### GitHub Token for Rate Limiting

Avoid GitHub API rate limits:

```bash
export GITHUB_TOKEN=your_token_here
lychee README.md
```

Or pass directly:

```bash
lychee --github-token $GITHUB_TOKEN README.md
```

## Exit Codes

Lychee exit codes indicate check results:

- `0` - All links valid
- `1` - Links have warnings (non-fatal)
- `2` - Broken links found
- Other - Execution error

**Use in scripts:**

```bash
if lychee README.md; then
  echo "All links valid"
else
  echo "Broken links found"
  exit 1
fi
```

## Configuration File

Use `lychee.toml` for persistent settings:

```bash
# Uses lychee.toml in current directory
lychee docs/

# Specify custom config
lychee --config custom-lychee.toml docs/
```

See `configuring-lychee` skill for configuration file details.

## Common Workflows

### Check Documentation Project

```bash
# With caching for repeated checks
lychee --cache --exclude 'localhost|127\.0\.0\.1' 'docs/**/*.md'
```

### Check Generated Static Site

```bash
# After building site
lychee --cache --root-dir $(pwd)/build --base-url https://mysite.com build/
```

### Check Specific Content Types

```bash
# Check only markdown files
lychee --extensions md,markdown README.md docs/

# Check markdown and HTML
lychee --extensions md,html,htm docs/
```

### Offline Mode

Check only local file references, block network requests:

```bash
lychee --offline docs/
```

### Quiet Mode for CI

```bash
# Minimal output
lychee --no-progress --quiet README.md

# Very quiet (errors only)
lychee --no-progress -qq README.md
```

## Additional Resources

### Related Skills

- **configuring-lychee** (in this plugin) - Create lychee.toml configuration files
- **lychee-github-workflows** (in this plugin) - Automate link checking in CI/CD

## Performance Tips

1. **Enable caching** with `--cache` for repeated checks
2. **Increase concurrency** with `--max-concurrency` for large sites (default: 128)
3. **Use exclude patterns** to skip known problematic domains
4. **Set reasonable timeouts** to avoid hanging on slow sites
5. **Configure max-cache-age** to balance freshness vs performance

## Troubleshooting

### Too Many Rate Limit Errors (429)

**Solution:** Accept 429 status or reduce concurrency:

```bash
lychee --accept '200..=299,429' README.md
# or
lychee --max-concurrency 10 README.md
```

### SSL/TLS Errors

**Solution:** Use `--insecure` flag (not recommended for production):

```bash
lychee --insecure docs/
```

### Timeout on Slow Sites

**Solution:** Increase timeout:

```bash
lychee --timeout 60 README.md
```

## Next Steps

1. Create `lychee.toml` for project-specific configuration
2. Set up GitHub Actions workflow for automated checking
3. Enable caching with `.lycheecache/` directory
4. Add lychee to pre-commit hooks or CI/CD pipeline
