---
name: creating-kickstart-templates
description: Create and author kickstart templates for project scaffolding. Use when the user wants to create a kickstart template, write template.toml, use Tera templating, add conditional questions, set up hooks, or build a project generator.
---

# Creating Kickstart Templates

This skill guides you through creating kickstart templates for project scaffolding.

## Template Structure

A kickstart template is a directory containing:

```
my-template/
├── template.toml              # Configuration (required)
├── {{project_name}}/          # Template files with variables
│   ├── README.md
│   └── src/
│       └── main.py
├── validate_vars.py           # Pre-gen hook (optional)
└── setup.sh                   # Post-gen hook (optional)
```

## Quick Links

- **template.toml reference**: [reference.md](reference.md)
- **Tera syntax**: [tera-syntax.md](tera-syntax.md)
- **Examples**: [examples.md](examples.md)

## Minimal Example

**template.toml**:
```toml
name = "My Template"
kickstart_version = 1

[[variables]]
name = "project_name"
default = "my-project"
prompt = "Project name?"
```

**{{project_name}}/README.md**:
```markdown
# {{ project_name | title_case }}

Welcome to {{ project_name }}!
```

## Variable Types

Variables are defined in `[[variables]]` sections:

```toml
# String variable
[[variables]]
name = "project_name"
default = "my-project"
prompt = "Project name?"
validation = "^[a-z][a-z0-9-]+$"  # Optional regex

# Boolean variable
[[variables]]
name = "use_docker"
default = true
prompt = "Include Docker support?"

# Choice variable
[[variables]]
name = "database"
default = "postgres"
prompt = "Which database?"
choices = ["postgres", "mysql", "sqlite"]

# Derived variable (computed, not prompted)
[[variables]]
name = "project_slug"
default = "{{ project_name | slugify }}"
derived = true
```

## Conditional Questions

Use `only_if` to ask questions based on previous answers:

```toml
[[variables]]
name = "database"
default = "postgres"
prompt = "Which database?"
choices = ["postgres", "mysql", "sqlite", "none"]

[[variables]]
name = "pg_version"
default = "15"
prompt = "PostgreSQL version?"
choices = ["15", "14", "13"]
only_if = { name = "database", value = "postgres" }
```

## File/Directory Templating

Use `{{ variable }}` in filenames and content:

- **Filenames**: `{{project_name}}/src/{{module_name}}.py`
- **Content**: `# {{ project_name | title_case }}`

**Windows note**: Use `$$` instead of `|` in filenames:
```
{{title $$ slugify}}.md  →  my-title.md
```

## Case Conversion Filters

| Filter | Result |
|--------|--------|
| `upper_camel_case` | `MyProject` |
| `camel_case` | `myProject` |
| `snake_case` | `my_project` |
| `kebab_case` | `my-project` |
| `shouty_snake_case` | `MY_PROJECT` |
| `title_case` | `My Project` |

## Workflow

1. Create `template.toml` with variables
2. Create template files with `{{ variable }}` placeholders
3. Test: `kickstart . -o test-output`
4. Validate: `kickstart validate template.toml`

## Common Patterns

### Conditional file cleanup

Remove files based on user choices:

```toml
[[cleanup]]
name = "use_docker"
value = false
paths = ["{{ project_name }}/Dockerfile", "{{ project_name }}/docker-compose.yml"]
```

### Files to skip templating

For files with Tera-like syntax (HTML, JSON):

```toml
copy_without_render = [
    "{{project_name}}/templates/*.html",
    "*.json"
]
```

### Hooks for validation/setup

```toml
[[pre_gen_hooks]]
name = "validate"
path = "validate.py"

[[post_gen_hooks]]
name = "install deps"
path = "setup.sh"
only_if = { name = "auto_install", value = true }
```
