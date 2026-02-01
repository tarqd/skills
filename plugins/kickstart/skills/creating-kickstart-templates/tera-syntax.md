# Tera Templating Syntax

Kickstart uses Tera (Jinja2-inspired) for templating in both filenames and file contents.

## Variable Substitution

```
{{ variable_name }}
{{ project_name }}
{{ author | upper }}
```

## Filters

Apply transformations with the pipe `|` operator:

```
{{ name | upper }}              → MYPROJECT
{{ name | lower }}              → myproject
{{ name | capitalize }}         → Myproject
{{ name | title }}              → My Project Title
{{ text | trim }}               → removes whitespace
{{ text | truncate(length=20) }} → truncates to 20 chars
```

### Case Conversion Filters

```
{{ name | upper_camel_case }}    → MyProjectName
{{ name | camel_case }}          → myProjectName
{{ name | snake_case }}          → my_project_name
{{ name | kebab_case }}          → my-project-name
{{ name | shouty_snake_case }}   → MY_PROJECT_NAME
{{ name | shouty_kebab_case }}   → MY-PROJECT-NAME
{{ name | title_case }}          → My Project Name
```

### String Filters

```
{{ text | replace(from="old", to="new") }}
{{ text | slugify }}             → my-project-name
{{ text | wordcount }}           → 5
{{ text | split(pat=",") }}      → ["a", "b", "c"]
{{ text | first }}               → first character
{{ text | last }}                → last character
{{ text | reverse }}             → reversed string
```

### Filename Filter Syntax

In filenames, use `$$` instead of `|` for Windows compatibility:

```
{{project_name $$ snake_case}}.py
{{title $$ slugify}}.md
{{name $$ upper_camel_case}}.java
```

## Conditionals

```jinja
{% if use_docker %}
Docker is enabled!
{% endif %}

{% if database == "postgres" %}
Using PostgreSQL
{% elif database == "mysql" %}
Using MySQL
{% else %}
No database
{% endif %}
```

### Boolean Checks

```jinja
{% if use_auth %}
  {% if auth_method == "jwt" %}
JWT authentication enabled
  {% endif %}
{% endif %}

{% if not skip_tests %}
Running tests...
{% endif %}
```

## Loops

```jinja
{% for item in items %}
- {{ item }}
{% endfor %}

{% for key, value in mapping %}
{{ key }}: {{ value }}
{% endfor %}
```

### Loop Variables

```jinja
{% for item in items %}
{{ loop.index }}     → 1-indexed position
{{ loop.index0 }}    → 0-indexed position
{{ loop.first }}     → true if first iteration
{{ loop.last }}      → true if last iteration
{% endfor %}
```

## Comments

```jinja
{# This is a comment and won't appear in output #}
```

## Whitespace Control

Use `-` to trim whitespace:

```jinja
{% if condition -%}
No leading whitespace
{%- endif %}

{{- variable -}}  → trims both sides
```

## Set Variables

```jinja
{% set full_name = first_name ~ " " ~ last_name %}
{% set items = ["a", "b", "c"] %}
```

## Include (in file content only)

```jinja
{% include "partials/header.html" %}
```

## Raw Blocks

Prevent Tera processing:

```jinja
{% raw %}
This {{ will_not }} be processed
{% endraw %}
```

## Common Patterns

### Conditional File Sections

```markdown
# {{ project_name }}

{{ description }}

{% if use_docker %}
## Docker

Run with Docker:
```bash
docker-compose up
```
{% endif %}

{% if database != "none" %}
## Database

This project uses {{ database }}.
{% endif %}
```

### Package/Namespace Handling

```toml
[[variables]]
name = "package"
default = "com.example.app"
prompt = "Package name?"

[[variables]]
name = "package_path"
default = "{{ package | replace(from='.', to='/') }}"
derived = true
```

Then in templates:
```
src/main/java/{{package_path}}/Main.java
```

### Conditional Imports

```python
{% if use_async %}
import asyncio
{% endif %}
{% if database == "postgres" %}
import asyncpg
{% elif database == "sqlite" %}
import aiosqlite
{% endif %}
```

### Dynamic Configuration

```yaml
# config.yml
name: {{ project_name }}
version: 0.1.0
{% if use_docker %}
docker:
  image: {{ project_name }}:latest
  port: {{ port | default(value=8080) }}
{% endif %}
```

## Escaping

To output literal `{{` or `}}`:

```jinja
{{ "{{" }}  → outputs {{
{{ "}}" }}  → outputs }}
```

Or use raw blocks for larger sections.
