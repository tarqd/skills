# template.toml Reference

Complete schema for kickstart template configuration files.

## Required Fields

```toml
name = "My Template"        # Template name
kickstart_version = 1       # Always 1
```

## Optional Metadata

```toml
description = "A template for Rust CLI applications"
version = "1.0.0"
url = "https://github.com/user/template"
authors = ["Author Name <email@example.com>"]
keywords = ["rust", "cli", "template"]
```

## Template Location

```toml
# If template files are in a subdirectory
directory = "template_root"

# Whether to follow symlinks when scanning
follow_symlinks = false
```

## Ignore Patterns

Files to exclude from the generated output:

```toml
ignore = [
    "README.md",           # Template's own README
    "CONTRIBUTING.md",
    ".travis.yml",
    "docs/",               # Template documentation
    "tests/",
]
```

## Copy Without Render

Files to copy as-is without Tera processing:

```toml
copy_without_render = [
    "{{project_name}}/templates/*.html",   # HTML with {{ }} syntax
    "*.json",                               # JSON files
    "**/*.j2",                              # Jinja2 templates
]
```

## Variables

### String Variable

```toml
[[variables]]
name = "project_name"
default = "my-project"
prompt = "What is the project name?"
validation = "^[a-z][a-z0-9_-]+$"   # Regex validation (optional)
```

### Boolean Variable

```toml
[[variables]]
name = "use_docker"
default = true
prompt = "Include Docker configuration?"
```

### Integer Variable

```toml
[[variables]]
name = "port"
default = 8080
prompt = "Server port?"
```

### Choice Variable

```toml
[[variables]]
name = "license"
default = "MIT"
prompt = "Choose a license:"
choices = ["MIT", "Apache-2.0", "GPL-3.0", "BSD-3-Clause"]
```

### Derived Variable

Computed from other variables, not prompted:

```toml
[[variables]]
name = "package_path"
default = "{{ package | replace(from='.', to='/') }}"
derived = true
```

### Conditional Variable

Only asked if a condition is met:

```toml
[[variables]]
name = "pg_version"
default = "15"
prompt = "PostgreSQL version?"
choices = ["15", "14", "13"]
only_if = { name = "database", value = "postgres" }
```

### Using Previous Variables in Defaults

```toml
[[variables]]
name = "project_name"
default = "my-app"
prompt = "Project name?"

[[variables]]
name = "binary_name"
default = "{{ project_name }}"
prompt = "Binary name?"
```

## Cleanup

Conditionally delete files after generation:

```toml
[[cleanup]]
name = "use_docker"
value = false
paths = [
    "{{ project_name }}/Dockerfile",
    "{{ project_name }}/docker-compose.yml",
    "{{ project_name }}/.dockerignore"
]

[[cleanup]]
name = "database"
value = "none"
paths = ["{{ project_name }}/src/db/"]
```

## Hooks

### Pre-Generation Hooks

Run after questions, before file generation:

```toml
[[pre_gen_hooks]]
name = "validate inputs"
path = "scripts/validate.py"

[[pre_gen_hooks]]
name = "check dependencies"
path = "scripts/check_deps.sh"
only_if = { name = "check_system", value = true }
```

### Post-Generation Hooks

Run after files are generated:

```toml
[[post_gen_hooks]]
name = "install dependencies"
path = "scripts/install.sh"
only_if = { name = "auto_install", value = true }

[[post_gen_hooks]]
name = "initialize git"
path = "scripts/git_init.sh"
```

## Hook Scripts

Hooks have access to all template variables as environment variables:

```python
#!/usr/bin/env python3
import os

project_name = os.environ.get('project_name', '')
use_docker = os.environ.get('use_docker', 'false') == 'true'

print(f"Setting up {project_name}...")
if use_docker:
    print("Docker support enabled")
```

```bash
#!/bin/bash
echo "Project: $project_name"
echo "Working directory: $(pwd)"
```

## Complete Example

```toml
name = "Python CLI Template"
kickstart_version = 1
description = "A modern Python CLI application template"
version = "1.0.0"
authors = ["Your Name <you@example.com>"]
keywords = ["python", "cli", "click"]

directory = "template"

ignore = [
    "README.md",
    "LICENSE",
    ".github/",
]

copy_without_render = [
    "{{project_name}}/templates/*.html",
]

[[cleanup]]
name = "use_docker"
value = false
paths = ["{{project_name}}/Dockerfile", "{{project_name}}/docker-compose.yml"]

[[pre_gen_hooks]]
name = "validate"
path = "hooks/validate.py"

[[post_gen_hooks]]
name = "setup"
path = "hooks/setup.sh"
only_if = { name = "auto_setup", value = true }

[[variables]]
name = "project_name"
default = "my-cli"
prompt = "Project name?"
validation = "^[a-z][a-z0-9_-]+$"

[[variables]]
name = "project_slug"
default = "{{ project_name | snake_case }}"
derived = true

[[variables]]
name = "description"
default = "A CLI application"
prompt = "Project description?"

[[variables]]
name = "author"
default = "Your Name"
prompt = "Author name?"

[[variables]]
name = "use_docker"
default = false
prompt = "Include Docker support?"

[[variables]]
name = "python_version"
default = "3.11"
prompt = "Python version?"
choices = ["3.12", "3.11", "3.10", "3.9"]

[[variables]]
name = "auto_setup"
default = true
prompt = "Run setup after generation?"
```

## Validation Rules

- `name` is required and must be unique within template
- `default` is required and determines the variable type
- Either `prompt` or `derived = true` must be present
- `choices` must include the `default` value
- `validation` regex must match the `default` value
- `only_if` must reference a previously defined variable
- Hook `path` must point to an existing executable file
