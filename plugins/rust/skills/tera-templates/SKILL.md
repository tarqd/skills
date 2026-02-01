---
name: tera-templates
description: Write Tera templates for Rust applications. Use when creating Jinja2/Django-style templates, using template inheritance, writing macros, applying filters, or generating HTML/text with Tera.
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Tera Templates

Tera is a powerful template engine for Rust inspired by Jinja2 and Django templates. Use this skill when writing `.html`, `.tera`, or other template files for Rust applications using the Tera crate.

## When to Activate

- Creating or editing Tera template files
- Setting up template inheritance with `extends` and `block`
- Writing template macros
- Using filters or tests in templates
- Generating HTML, XML, or text output with Tera

## Quick Start

### Basic Template Syntax

```jinja2
{# This is a comment #}

{# Variable output #}
Hello, {{ name }}!

{# Expressions #}
{{ price * quantity }}

{# Filters #}
{{ name | upper }}
{{ text | truncate(length=50) }}
```

### Delimiters

| Delimiter | Purpose |
|-----------|---------|
| `{{ }}` | Expressions - output values |
| `{% %}` | Statements - control flow |
| `{# #}` | Comments - not rendered |

### Whitespace Control

Add `-` to trim whitespace:
- `{%-` removes whitespace before
- `-%}` removes whitespace after
- Works with all delimiters: `{{-`, `-}}`, `{#-`, `-#}`

```jinja2
{% set my_var = 2 -%}
{{ my_var }}
```

## Template Inheritance

### Base Template (`base.html`)

```jinja2
<!DOCTYPE html>
<html>
<head>
    {% block head %}
    <title>{% block title %}{% endblock title %} - My Site</title>
    {% endblock head %}
</head>
<body>
    {% block content %}{% endblock content %}

    {% block footer %}
    <footer>&copy; 2024</footer>
    {% endblock footer %}
</body>
</html>
```

### Child Template

```jinja2
{% extends "base.html" %}

{% block title %}Home{% endblock title %}

{% block head %}
    {{ super() }}
    <link rel="stylesheet" href="home.css">
{% endblock head %}

{% block content %}
    <h1>Welcome!</h1>
{% endblock content %}
```

Use `{{ super() }}` to include parent block content.

## Control Structures

### Conditionals

```jinja2
{% if price < 10 %}
    Cheap!
{% elif price > 100 %}
    Expensive!
{% else %}
    Reasonable.
{% endif %}

{# Negation #}
{% if not logged_in %}
    Please log in.
{% endif %}

{# Combine with and/or #}
{% if user and user.is_admin %}
    Admin panel
{% endif %}
```

### Loops

```jinja2
{% for item in items %}
    {{ loop.index }}. {{ item.name }}
{% endfor %}

{# Key-value iteration #}
{% for key, value in my_map %}
    {{ key }}: {{ value }}
{% endfor %}

{# Empty fallback #}
{% for item in items %}
    {{ item }}
{% else %}
    No items found.
{% endfor %}
```

**Loop variables:**
- `loop.index` - 1-indexed position
- `loop.index0` - 0-indexed position
- `loop.first` - true on first iteration
- `loop.last` - true on last iteration

**Loop controls:**
```jinja2
{% for item in items %}
    {% if item.skip %}{% continue %}{% endif %}
    {% if item.stop %}{% break %}{% endif %}
    {{ item.name }}
{% endfor %}
```

## Macros

Define reusable template components:

```jinja2
{# In macros.html #}
{% macro input(label, type="text", name="") %}
    <label>
        {{ label }}
        <input type="{{ type }}" name="{{ name }}">
    </label>
{% endmacro input %}

{% macro button(text, class="btn") %}
    <button class="{{ class }}">{{ text }}</button>
{% endmacro button %}
```

Use macros:

```jinja2
{% import "macros.html" as forms %}

{{ forms::input(label="Username", name="user") }}
{{ forms::button(text="Submit", class="btn-primary") }}

{# Call macro in same file with self:: #}
{{ self::my_macro(arg="value") }}
```

## Includes

```jinja2
{% include "header.html" %}

{# Ignore if missing #}
{% include "optional.html" ignore missing %}

{# Try multiple files #}
{% include ["custom/nav.html", "nav.html"] %}
```

## Assignments

```jinja2
{% set name = "Alice" %}
{% set total = price * quantity %}
{% set items = [1, 2, 3] %}

{# Global assignment (escapes loop scope) #}
{% for item in items %}
    {% set_global count = loop.index %}
{% endfor %}
```

## Built-in Filters Reference

See [filters.md](filters.md) for the complete list.

**Common filters:**
```jinja2
{{ name | lower }}              {# lowercase #}
{{ name | upper }}              {# uppercase #}
{{ name | capitalize }}         {# First letter upper #}
{{ name | title }}              {# Title Case #}
{{ text | truncate(length=50) }} {# truncate with ellipsis #}
{{ text | wordcount }}          {# count words #}
{{ text | replace(from="a", to="b") }}
{{ text | trim }}               {# remove whitespace #}
{{ items | length }}            {# array/string length #}
{{ items | first }}             {# first element #}
{{ items | last }}              {# last element #}
{{ items | reverse }}           {# reverse array #}
{{ items | sort }}              {# sort array #}
{{ items | join(sep=", ") }}    {# join array to string #}
{{ num | round }}               {# round number #}
{{ num | abs }}                 {# absolute value #}
{{ content | safe }}            {# disable escaping #}
{{ value | default(value="N/A") }}  {# default if undefined #}
{{ data | json_encode(pretty=true) }} {# to JSON #}
```

## Built-in Tests

```jinja2
{% if num is odd %}
{% if num is even %}
{% if num is divisibleby(3) %}
{% if var is defined %}
{% if var is undefined %}
{% if val is string %}
{% if val is number %}
{% if val is iterable %}
{% if name is starting_with("Dr.") %}
{% if name is ending_with("Jr.") %}
{% if list is containing("item") %}
{% if name is matching("^[A-Z]") %}
```

## Built-in Functions

```jinja2
{# Generate range #}
{% for i in range(end=5) %}
{% for i in range(start=1, end=10, step_by=2) %}

{# Current time (requires builtins feature) #}
{{ now() }}
{{ now() | date(format="%Y-%m-%d") }}
{{ now(timestamp=true) }}

{# Random number #}
{{ get_random(end=100) }}
{{ get_random(start=10, end=20) }}

{# Environment variable #}
{{ get_env(name="HOME") }}
{{ get_env(name="MISSING", default="fallback") }}

{# Throw error #}
{% if not valid %}
    {{ throw(message="Validation failed!") }}
{% endif %}
```

## Raw Blocks

Prevent Tera from processing content:

```jinja2
{% raw %}
    This {{ will_not }} be processed.
    Useful for JavaScript templates or documentation.
{% endraw %}
```

## Special Variables

```jinja2
{# Debug: print entire context #}
{{ __tera_context }}
```

## Best Practices

1. **Use inheritance** - Create a `base.html` and extend it
2. **Extract macros** - Put reusable components in `macros.html`
3. **Whitespace control** - Use `{%-` and `-%}` to keep output clean
4. **Safe filter last** - `{{ content | other_filter | safe }}`
5. **Avoid complex logic** - Keep templates simple, prepare data in Rust

## Quick Links

- [Complete Filter Reference](filters.md)
- [Official Documentation](https://keats.github.io/tera/docs/)
- [API Docs](https://docs.rs/tera)
