# Kickstart Template Examples

## Minimal Template

The simplest possible template:

```
minimal/
├── template.toml
└── {{project_name}}/
    └── README.md
```

**template.toml**:
```toml
name = "Minimal"
kickstart_version = 1

[[variables]]
name = "project_name"
default = "my-project"
prompt = "Project name?"
```

**{{project_name}}/README.md**:
```markdown
# {{ project_name | title_case }}

This is {{ project_name }}.
```

## Python CLI Template

```
python-cli/
├── template.toml
├── {{project_name}}/
│   ├── README.md
│   ├── pyproject.toml
│   ├── src/
│   │   └── {{project_slug}}/
│   │       ├── __init__.py
│   │       └── cli.py
│   └── tests/
│       └── test_cli.py
└── hooks/
    └── setup.sh
```

**template.toml**:
```toml
name = "Python CLI"
kickstart_version = 1

[[post_gen_hooks]]
name = "setup"
path = "hooks/setup.sh"
only_if = { name = "run_setup", value = true }

[[variables]]
name = "project_name"
default = "my-cli"
prompt = "Project name?"
validation = "^[a-z][a-z0-9-]+$"

[[variables]]
name = "project_slug"
default = "{{ project_name | snake_case }}"
derived = true

[[variables]]
name = "description"
default = "A CLI application"
prompt = "Description?"

[[variables]]
name = "python_version"
default = "3.11"
prompt = "Python version?"
choices = ["3.12", "3.11", "3.10"]

[[variables]]
name = "run_setup"
default = true
prompt = "Run setup after generation?"
```

**{{project_name}}/pyproject.toml**:
```toml
[project]
name = "{{ project_name }}"
version = "0.1.0"
description = "{{ description }}"
requires-python = ">={{ python_version }}"

[project.scripts]
{{ project_name }} = "{{ project_slug }}.cli:main"
```

## Rust Project with Conditional Features

```
rust-app/
├── template.toml
├── {{project_name}}/
│   ├── Cargo.toml
│   ├── src/
│   │   └── main.rs
│   ├── Dockerfile
│   └── docker-compose.yml
```

**template.toml**:
```toml
name = "Rust Application"
kickstart_version = 1

[[cleanup]]
name = "use_docker"
value = false
paths = [
    "{{project_name}}/Dockerfile",
    "{{project_name}}/docker-compose.yml"
]

[[variables]]
name = "project_name"
default = "my-app"
prompt = "Project name?"

[[variables]]
name = "use_async"
default = true
prompt = "Use async runtime (tokio)?"

[[variables]]
name = "use_docker"
default = false
prompt = "Include Docker support?"
```

**{{project_name}}/Cargo.toml**:
```toml
[package]
name = "{{ project_name }}"
version = "0.1.0"
edition = "2021"

[dependencies]
{% if use_async %}
tokio = { version = "1", features = ["full"] }
{% endif %}
```

**{{project_name}}/src/main.rs**:
```rust
{% if use_async %}
#[tokio::main]
async fn main() {
    println!("Hello from {{ project_name }}!");
}
{% else %}
fn main() {
    println!("Hello from {{ project_name }}!");
}
{% endif %}
```

## Web App with Database Choice

```
web-app/
├── template.toml
├── {{project_name}}/
│   ├── README.md
│   ├── src/
│   │   ├── main.py
│   │   └── db.py
│   └── docker-compose.yml
```

**template.toml**:
```toml
name = "Web Application"
kickstart_version = 1

copy_without_render = [
    "{{project_name}}/templates/*.html"
]

[[cleanup]]
name = "database"
value = "none"
paths = ["{{project_name}}/src/db.py"]

[[variables]]
name = "project_name"
default = "my-web-app"
prompt = "Project name?"

[[variables]]
name = "database"
default = "postgres"
prompt = "Database?"
choices = ["postgres", "mysql", "sqlite", "none"]

[[variables]]
name = "pg_version"
default = "15"
prompt = "PostgreSQL version?"
choices = ["16", "15", "14"]
only_if = { name = "database", value = "postgres" }

[[variables]]
name = "mysql_version"
default = "8.0"
prompt = "MySQL version?"
choices = ["8.0", "5.7"]
only_if = { name = "database", value = "mysql" }
```

**{{project_name}}/docker-compose.yml**:
```yaml
version: "3.8"
services:
  app:
    build: .
    ports:
      - "8000:8000"
{% if database == "postgres" %}
  db:
    image: postgres:{{ pg_version }}
    environment:
      POSTGRES_DB: {{ project_name | snake_case }}
      POSTGRES_PASSWORD: secret
{% elif database == "mysql" %}
  db:
    image: mysql:{{ mysql_version }}
    environment:
      MYSQL_DATABASE: {{ project_name | snake_case }}
      MYSQL_ROOT_PASSWORD: secret
{% endif %}
```

## Monorepo with Multiple Templates

Structure for a repo containing multiple templates:

```
templates-repo/
├── README.md
├── templates/
│   ├── python-cli/
│   │   ├── template.toml
│   │   └── {{project_name}}/
│   ├── rust-lib/
│   │   ├── template.toml
│   │   └── {{crate_name}}/
│   └── node-api/
│       ├── template.toml
│       └── {{project_name}}/
```

Use with the `-d` flag:
```bash
kickstart https://github.com/user/templates-repo -d templates/python-cli
kickstart https://github.com/user/templates-repo -d templates/rust-lib
```

## Template with Hooks

```
with-hooks/
├── template.toml
├── hooks/
│   ├── validate.py
│   └── setup.sh
└── {{project_name}}/
    └── ...
```

**template.toml**:
```toml
name = "With Hooks"
kickstart_version = 1

[[pre_gen_hooks]]
name = "validate"
path = "hooks/validate.py"

[[post_gen_hooks]]
name = "setup"
path = "hooks/setup.sh"

[[variables]]
name = "project_name"
default = "my-project"
prompt = "Project name?"
```

**hooks/validate.py**:
```python
#!/usr/bin/env python3
import os
import sys

project_name = os.environ.get('project_name', '')

# Validation logic
if len(project_name) < 3:
    print("Error: Project name must be at least 3 characters")
    sys.exit(1)

if project_name.startswith('-'):
    print("Error: Project name cannot start with a hyphen")
    sys.exit(1)

print(f"Validated: {project_name}")
```

**hooks/setup.sh**:
```bash
#!/bin/bash
set -e

echo "Setting up $project_name..."
cd "$project_name"

# Initialize git
git init
git add .
git commit -m "Initial commit"

echo "Done! Your project is ready."
```

## Java Package Template

Demonstrates using derived variables for package paths:

**template.toml**:
```toml
name = "Java Application"
kickstart_version = 1

[[variables]]
name = "group_id"
default = "com.example"
prompt = "Group ID?"

[[variables]]
name = "artifact_id"
default = "myapp"
prompt = "Artifact ID?"

[[variables]]
name = "package"
default = "{{ group_id }}.{{ artifact_id }}"
derived = true

[[variables]]
name = "package_path"
default = "{{ package | replace(from='.', to='/') }}"
derived = true
```

Directory structure:
```
{{artifact_id}}/
└── src/main/java/{{package_path}}/
    └── Main.java
```

This creates: `myapp/src/main/java/com/example/myapp/Main.java`
