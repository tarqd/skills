#!/usr/bin/env bash
# {{ hook_event }} hook: {{ description }}
#
# Exit codes:
#   0 = Success/Allow (stdout visible to Claude)
#   2 = Block (stderr shown as feedback, blocks the action)
#   Other = Warning (stderr shown, but action proceeds)
#
# Environment variables available:
#   - CLAUDE_PLUGIN_ROOT: Absolute path to the plugin root
#   - CLAUDE_PROJECT_DIR: Project root directory
#
# For PreToolUse/PostToolUse:
#   - TOOL_NAME: Name of the tool
#   - TOOL_INPUT: JSON input to the tool
#
# For UserPromptSubmit:
#   - PROMPT: The user's prompt text
#
# For SessionStart:
#   - CLAUDE_ENV_FILE: File to write persistent env vars

set -euo pipefail

{% if hook_event == 'PreToolUse' %}
# PreToolUse: Validate before tool execution
# Example: Block dangerous rm commands
# if [[ "$TOOL_NAME" == "Bash" ]]; then
#     INPUT_CMD=$(echo "$TOOL_INPUT" | jq -r '.command // empty')
#     if [[ "$INPUT_CMD" == *"rm -rf /"* ]]; then
#         echo "Blocked: Refusing to run destructive command" >&2
#         exit 2
#     fi
# fi

echo "PreToolUse: $TOOL_NAME"
{% elif hook_event == 'PostToolUse' %}
# PostToolUse: React after tool completes
# Example: Run linter after file edits
# if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
#     FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .filePath // empty')
#     if [[ -n "$FILE_PATH" && -f "$FILE_PATH" ]]; then
#         # Run your linter/formatter here
#         echo "File modified: $FILE_PATH"
#     fi
# fi

echo "PostToolUse: $TOOL_NAME completed"
{% elif hook_event == 'SessionStart' %}
# SessionStart: Initialize session
# Example: Set up environment variables
# echo "MY_VAR=value" >> "$CLAUDE_ENV_FILE"

echo "✓ {{ hook_name }} hook loaded"
{% elif hook_event == 'SessionEnd' %}
# SessionEnd: Cleanup on session end

echo "Session ended"
{% elif hook_event == 'UserPromptSubmit' %}
# UserPromptSubmit: Process user prompts
# Example: Add warnings for certain keywords
# if echo "$PROMPT" | grep -qi "production"; then
#     echo "Warning: You mentioned production. Please proceed carefully." >&2
#     exit 1  # Warning, doesn't block
# fi

# Pass through
exit 0
{% elif hook_event == 'Stop' %}
# Stop: Before Claude stops responding
# Example: Ensure cleanup happens

echo "Claude is stopping"
{% elif hook_event == 'SubagentStop' %}
# SubagentStop: Before a subagent stops

echo "Subagent stopping"
{% elif hook_event == 'Notification' %}
# Notification: When Claude sends a notification

echo "Notification received"
{% elif hook_event == 'PreCompact' %}
# PreCompact: Before conversation compaction

echo "About to compact conversation"
{% else %}
# Default handler
exit 0
{% endif %}

exit 0
