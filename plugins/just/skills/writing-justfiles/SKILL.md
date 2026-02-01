---
name: writing-justfiles
description: Write justfiles for the just command runner. Use when creating justfiles, writing recipes, defining variables, using just functions, configuring settings, or organizing recipes with modules.
---

# Writing Justfiles

Just is a command runner with a Make-inspired syntax. Justfiles define recipes (commands) that can be run with `just recipe-name`.

## Quick Start

```just
# This is a comment
default: build test

build:
    cargo build --release

test:
    cargo test

clean:
    rm -rf target/
```

## Quick Links

- [Recipes](recipes.md) - Parameters, dependencies, attributes
- [Variables](variables.md) - Strings, operators, assignments
- [Functions](functions.md) - Built-in functions reference
- [Settings](settings.md) - Configuration options
- [Modules](modules.md) - Imports and namespacing

## Recipe Basics

```just
# Simple recipe
build:
    cargo build

# With dependencies (run first)
release: clean build
    cargo build --release

# With parameters
greet name:
    echo "Hello, {{name}}!"

# Default parameter
serve port="8080":
    python -m http.server {{port}}

# Variadic parameters
test +files:
    cargo test {{files}}
```

## Variables

```just
version := "1.0.0"
target := "release"

build:
    cargo build --{{target}}
    echo "Built version {{version}}"
```

## Common Patterns

### Default Recipe

```just
# First recipe is default, or use [default] attribute
default: build test

# Or explicit default
[default]
all: build test lint
```

### Quiet Recipes

```just
# Suppress command echoing with @
@build:
    cargo build

# Or per-line
install:
    @echo "Installing..."
    cargo install --path .
```

### Conditional Platform

```just
[linux]
install:
    sudo apt install package

[macos]
install:
    brew install package

[windows]
install:
    choco install package
```

### Groups

```just
[group('build')]
build:
    cargo build

[group('build')]
release:
    cargo build --release

[group('test')]
test:
    cargo test
```

### Confirmation

```just
[confirm]
deploy:
    ./deploy.sh production

[confirm("Delete all data?")]
reset-db:
    psql -c "DROP DATABASE app"
```

### Shebang Recipes

```just
# Python recipe
analyze:
    #!/usr/bin/env python3
    import json
    data = json.load(open('data.json'))
    print(f"Found {len(data)} items")

# Bash with options
backup:
    #!/usr/bin/env bash
    set -euo pipefail
    tar -czf backup.tar.gz data/
```

## Essential Settings

```just
# Load .env file
set dotenv-load

# Export all variables as environment variables
set export

# Use different shell
set shell := ["bash", "-uc"]

# Suppress command echoing
set quiet
```

## Project Structure

For larger projects, use modules:

```just
# justfile
mod build
mod test
mod deploy

default: build::all test::unit
```

```just
# build.just
[default]
all: debug release

debug:
    cargo build

release:
    cargo build --release
```

## Tips

- Indent with spaces or tabs, but be consistent
- Use `{{variable}}` syntax (double braces)
- First recipe is the default unless `[default]` is used
- Recipes fail fast on first error (use `-` prefix to continue)
- Use `@` to suppress command echoing
- Use `_` prefix or `[private]` to hide from `--list`
