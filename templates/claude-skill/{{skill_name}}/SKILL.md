---
name: {{ skill_name }}
description: {{ skill_description }}. Use when {{ trigger_description }}.
allowed-tools: {{ allowed_tools }}
---

# {{ skill_title }}

{{ skill_description }}.

## When to Activate

This skill activates when:

- {{ trigger_description | capitalize }}
- User explicitly asks about [related topic]
- Working with [relevant files/context]

## Purpose

[Explain the skill's primary purpose and what problems it solves]

## Workflow

### 1. Understand the Context

First, gather information about what the user needs:

- Check for relevant files or configurations
- Understand the current state

### 2. Analyze

Examine the situation:

- [What to look for]
- [Key indicators]
- [Important patterns]

### 3. Provide Guidance

Based on the analysis:

1. [First step or recommendation]
2. [Second step]
3. [Third step]

## Key Concepts

### [Concept 1]

[Explanation of the first key concept]

### [Concept 2]

[Explanation of the second key concept]

## Quick Reference

| Term | Description |
|------|-------------|
| [Term 1] | [Definition] |
| [Term 2] | [Definition] |
| [Term 3] | [Definition] |

## Common Patterns

### Pattern 1: [Name]

[Description and example]

### Pattern 2: [Name]

[Description and example]

## Tips

- [Helpful tip 1]
- [Helpful tip 2]
- [Helpful tip 3]

## Quick Links
{% if include_reference %}
- [Reference](reference.md) - Detailed reference documentation
{% endif %}{% if include_examples %}
- [Examples](examples.md) - Real-world usage examples
{% endif %}
