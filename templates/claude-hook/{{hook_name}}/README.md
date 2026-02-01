# {{ hook_name | title_case }}

{{ description }}

## Hook Configuration

This hook configuration responds to **{{ hook_event }}** events.

{% if hook_event == 'PreToolUse' or hook_event == 'PostToolUse' %}
### Tool Matcher

Pattern: `{{ matcher }}`

This pattern matches tool names using regex. Examples:
- `*` - Match all tools
- `Write|Edit` - Match Write or Edit tools
- `Bash` - Match only Bash tool
- `mcp__.*` - Match all MCP tools
{% endif %}

## Implementation

{% if hook_type == 'command' %}
**Type**: Shell command

The hook runs `scripts/hook.sh` which:
- Receives context via environment variables
- Returns exit code to control behavior:
  - `0` = Allow/Success
  - `2` = Block (with feedback)
  - Other = Warning (non-blocking)
{% elif hook_type == 'prompt' %}
**Type**: LLM prompt

The hook evaluates using an LLM with the prompt:
> {{ prompt_text }}

The model analyzes the context and returns a decision.
{% else %}
**Type**: Agent

The hook runs an agentic verifier with access to tools:
- Read, Grep, Glob

This allows the hook to inspect files and make informed decisions.
{% endif %}

## Usage

Copy this hook configuration to your plugin's `hooks/` directory, or reference it in your `plugin.json`:

```json
{
  "hooks": "path/to/{{ hook_name }}/hooks.json"
}
```

## Exit Codes

| Code | Meaning | Behavior |
|------|---------|----------|
| 0 | Success | Action proceeds, stdout visible to Claude |
| 2 | Block | Action blocked, stderr shown as feedback |
| Other | Warning | Action proceeds, stderr shown as warning |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_PLUGIN_ROOT` | Absolute path to plugin root |
| `CLAUDE_PROJECT_DIR` | Project root directory |
| `TOOL_NAME` | Name of the tool (Pre/PostToolUse) |
| `TOOL_INPUT` | JSON input to tool (Pre/PostToolUse) |
| `PROMPT` | User's prompt (UserPromptSubmit) |
