# Lychee Link Checker Plugin

A comprehensive plugin for using [lychee](https://github.com/lycheeverse/lychee), a fast, async link checker written in Rust. This plugin helps Claude understand how to install, configure, and use lychee for link validation in documentation projects.

## Features

- **Installation guidance**: Install lychee via cargo, package managers, or pre-built binaries
- **CLI usage**: Run lychee to check links in markdown, HTML, and other document formats
- **Configuration**: Create and customize `lychee.toml` configuration files
- **GitHub Actions**: Generate workflows for PR link checking and scheduled link validation

## Skills

### installing-lychee
Guides installation of lychee across different platforms and package managers.

**Triggers when**: User needs to install or set up lychee

### using-lychee
Instructions for running lychee CLI commands, interpreting output, and handling various content types.

**Triggers when**: User wants to check links in documentation or files

### configuring-lychee
Creating and customizing `lychee.toml` configuration files with remapping, excludes, and other options.

**Triggers when**: User needs to configure link checking behavior

### lychee-github-workflows
Generate GitHub Actions workflows for automated link checking on PRs and schedules.

**Triggers when**: User wants to set up CI/CD link validation

## Optional: Proactive Link Checking

If you want Claude to proactively check links while working on documentation, you have several options:

### Option 1: Ask When Needed (Default)

Simply ask Claude: "Check the links in this file" - The skills handle the rest.

### Option 2: Custom Instructions

Add to your `~/.claude/CLAUDE.md` or project `CLAUDE.md`:

```markdown
When working on markdown or HTML documentation files, proactively check links
using `lychee --cache <file>` after substantial updates or at natural checkpoints.
Be non-intrusive during rapid iteration.
```

### Option 3: Automatic Hook (Silent Unless Broken)

For automatic checking that only reports broken links (zero token cost when links are valid).

**See `examples/check-links-hook.sh` for a complete, ready-to-use script.**

Or create your own at `.claude/hooks/check-links.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Read hook input
input=$(cat)

# Extract file path and tool name
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

# Only check Write/Edit operations
if [[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]]; then
  exit 0
fi

# Only check .md and .html files
if [[ ! "$file_path" =~ \.(md|html)$ ]]; then
  exit 0
fi

# Only check if file exists and lychee is installed
if [[ ! -f "$file_path" ]] || ! command -v lychee &> /dev/null; then
  exit 0
fi

# Run lychee with cache, capture output and exit code
output=$(lychee --cache --no-progress --format compact "$file_path" 2>&1) || exit_code=$?

# If all links valid (exit code 0), stay silent
if [[ ${exit_code:-0} -eq 0 ]]; then
  exit 0
fi

# If broken links found, report them
echo "{\"systemMessage\": \"⚠️  Broken links detected in $file_path:\\n\\n$output\"}"
exit 0  # Non-blocking
```

Make it executable:
```bash
chmod +x .claude/hooks/check-links.sh
```

Add to `.claude/settings.json`:
```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "bash .claude/hooks/check-links.sh",
          "timeout": 30
        }
      ]
    }
  ]
}
```

**Benefits:**
- Zero tokens when links are valid (silent success)
- Only reports problems
- Deterministic (no LLM decision overhead)
- Works with LYCHEE_HOOK_ARGS if you set it

**Trade-offs:**
- Always runs (may slow down rapid iteration)
- Less context-aware than Claude's judgment
- Requires bash and jq

**Quick Install:**
```bash
# From plugin directory
cp examples/check-links-hook.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/check-links-hook.sh

# Then add the hook config to .claude/settings.json
```

### Option 4: Session Context Hook

For LLM-guided checking with minimal token cost:

```json
{
  "SessionStart": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "prompt",
          "prompt": "When working with markdown (.md) or HTML (.html) files, consider checking links with lychee at natural checkpoints. Be non-intrusive during rapid iteration.",
          "timeout": 5
        }
      ]
    }
  ]
}
```

---

**Recommendation:** Start with Option 1 (ask when needed). Add automation only if you find yourself repeatedly asking for link checks.

## Prerequisites

- **lychee** must be installed (the `installing-lychee` skill will guide you)
- For GitHub Actions workflows: Repository with Actions enabled

## Installation

Add to your Claude Code plugins directory or install from the marketplace.

## Usage Examples

**Install lychee:**
```
"Help me install lychee on my system"
```

**Check links in documentation:**
```
"Check all links in my docs/ directory"
"Run lychee on README.md"
```

**Create configuration:**
```
"Create a lychee.toml that excludes example.com and allows 404s on github.com"
```

**Set up GitHub Actions:**
```
"Create a GitHub workflow to check links on PRs"
"Add a scheduled workflow to check links daily"
```

## Tips

- **Add `.lycheecache/` to .gitignore** - Lychee stores cached results here for faster repeated checks
- Configure `lychee.toml` for project-specific link checking rules
- Ask Claude to check links anytime: "Check the links in this file"
- Use `--preprocess` flag when working with PDF or other non-standard formats (requires appropriate converters)
- Start with lenient configuration, gradually tighten as you fix links
- For proactive checking, add custom instructions (see Optional section below)

## Quick Start

1. Install lychee: `brew install lychee` (or see `installing-lychee` skill)
2. Create `lychee.toml` configuration (see `configuring-lychee` skill)
3. Add `.lycheecache/` to your `.gitignore`
4. Run your first check: `lychee --cache README.md`
5. Set up GitHub Actions workflows (see `lychee-github-workflows` skill)

## License

MIT License - see LICENSE file for details.

## Links

- [lychee GitHub](https://github.com/lycheeverse/lychee)
- [lychee documentation](https://lychee.cli.rs/)
