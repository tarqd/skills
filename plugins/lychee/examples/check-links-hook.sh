#!/bin/bash
# Example PostToolUse hook for automatic link checking
# Only reports output when broken links are found (zero tokens when valid)
#
# Installation:
# 1. Copy to .claude/hooks/check-links.sh
# 2. chmod +x .claude/hooks/check-links.sh
# 3. Add to .claude/settings.json:
#    {
#      "PostToolUse": [{
#        "matcher": "Write|Edit",
#        "hooks": [{
#          "type": "command",
#          "command": "bash .claude/hooks/check-links.sh",
#          "timeout": 30
#        }]
#      }]
#    }

set -euo pipefail

# Read hook input from stdin
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

# Build lychee command with optional extra args from environment
lychee_cmd="lychee --cache --no-progress --format compact"
if [[ -n "${LYCHEE_HOOK_ARGS:-}" ]]; then
  lychee_cmd="$lychee_cmd $LYCHEE_HOOK_ARGS"
fi

# Run lychee, capture output and exit code
output=$($lychee_cmd "$file_path" 2>&1) || exit_code=$?

# If all links valid (exit code 0), stay silent (zero token cost)
if [[ ${exit_code:-0} -eq 0 ]]; then
  exit 0
fi

# If broken links found, report them to Claude
echo "{\"systemMessage\": \"⚠️  Broken links detected in $file_path:\\n\\n$output\"}"

# Exit 0 to be non-blocking (don't prevent the write/edit)
exit 0
