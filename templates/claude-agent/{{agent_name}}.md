---
name: {{ agent_name }}
description: {{ agent_description }}. {% if proactive %}PROACTIVELY {% endif %}Use when {{ trigger_description }}.
tools: {{ tools }}
model: {{ model }}
---

# {{ agent_title }} Agent

{{ agent_description }}.

## What This Agent Does

[Detailed description of the agent's responsibilities and specialization]

## Capabilities

1. **[Capability 1]**: [Description of what this capability involves]
2. **[Capability 2]**: [Description of what this capability involves]
3. **[Capability 3]**: [Description of what this capability involves]

## When to Use This Agent

{% if proactive %}
This agent is invoked **proactively** when:
{% else %}
Invoke this agent when:
{% endif %}

- {{ trigger_description | capitalize }}
- [Additional scenario 1]
- [Additional scenario 2]

## How It Proceeds

1. **Gather**: Collects relevant information using available tools
2. **Analyze**: Examines the data to understand the situation
3. **Evaluate**: Applies domain expertise to assess findings
4. **Report**: Returns structured findings to the main conversation

## Output Format

The agent provides:

- **Summary**: Brief overview of findings
- **Details**: Specific observations and data points
- **Recommendations**: Suggested next steps or actions

## Tool Access

This agent has access to:
{% if tools == "Read, Grep, Glob" %}
- **Read**: For reading files and documentation
- **Grep**: For searching code patterns
- **Glob**: For finding files by pattern

*Note: This agent cannot modify files - it's read-only for safety.*
{% elif tools == "Read, Grep, Glob, Bash" %}
- **Read**: For reading files and documentation
- **Grep**: For searching code patterns
- **Glob**: For finding files by pattern
- **Bash**: For running commands and scripts

*Note: This agent can run commands but cannot edit files directly.*
{% elif tools == "Read, Grep, Glob, Bash, Write, Edit" %}
- **Read**: For reading files and documentation
- **Grep**: For searching code patterns
- **Glob**: For finding files by pattern
- **Bash**: For running commands and scripts
- **Write/Edit**: For creating and modifying files

*Note: This agent has full file access - use with appropriate oversight.*
{% else %}
- All standard tools except Task (cannot spawn sub-agents)
{% endif %}

## Example Invocation

```
Use the {{ agent_name }} agent to [describe typical task]
```

## Notes

- [Important limitation or constraint]
- [Best practice for using this agent]
- [Any edge cases to be aware of]
