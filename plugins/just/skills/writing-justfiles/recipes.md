# Recipes Reference

## Basic Recipe

```just
recipe-name:
    command1
    command2
```

Commands are indented with spaces or tabs. Each line runs in a separate shell unless using shebang.

## Parameters

### Positional Parameters

```just
build target:
    cargo build --target {{target}}
```

### Default Values

```just
serve port="8080" host="localhost":
    python -m http.server {{port}} --bind {{host}}
```

### Variadic Parameters

```just
# One or more arguments (required)
test +files:
    cargo test {{files}}

# Zero or more arguments (optional)
run *args:
    ./app {{args}}
```

### Exported Parameters

Parameters exported as environment variables:

```just
build $RUST_BACKTRACE="1":
    cargo build
```

### Parameter Patterns

Validate parameters with regex:

```just
[arg('port', pattern='\d+')]
serve port:
    python -m http.server {{port}}
```

### Long/Short Options

```just
[arg('name', short='n', long='name')]
greet name:
    echo "Hello, {{name}}"
```

Usage: `just greet --name Alice` or `just greet -n Alice`

## Dependencies

### Prior Dependencies

Run before the recipe:

```just
release: clean build test
    cargo build --release
```

### Subsequent Dependencies

Run after the recipe:

```just
deploy: build && notify
    ./deploy.sh
```

### Dependencies with Arguments

```just
push: (build "release")
    git push

build target:
    cargo build --{{target}}
```

### Parallel Dependencies

```just
[parallel]
all: build test lint
```

## Attributes

### Visibility

```just
# Private recipe (not shown in --list)
[private]
_helper:
    echo "helper"

# Also private (underscore prefix)
_internal:
    echo "internal"
```

### Documentation

```just
# Comment becomes documentation
build:
    cargo build

# Custom documentation
[doc("Build the project in release mode")]
release:
    cargo build --release
```

### Groups

```just
[group('build')]
debug:
    cargo build

[group('build')]
release:
    cargo build --release
```

### Platform-Specific

```just
[linux]
install:
    sudo apt install pkg

[macos]
install:
    brew install pkg

[windows]
install:
    choco install pkg

[unix]  # Linux, macOS, BSD
open:
    xdg-open .
```

### Confirmation

```just
[confirm]
delete:
    rm -rf data/

[confirm("Are you sure you want to deploy to production?")]
deploy-prod:
    ./deploy.sh production
```

### Quiet/Verbose

```just
[quiet]
silent-recipe:
    echo "not shown"

[no-quiet]
loud-recipe:
    echo "always shown"
```

### Working Directory

```just
[working-directory('frontend')]
build-ui:
    npm run build

[no-cd]
global-install:
    cargo install --path .
```

### Script Recipes

```just
[script]
analyze:
    import json
    print("Python script!")

[script('node')]
process:
    console.log("JavaScript!");
```

### Extension for Shebang

```just
[extension('.py')]
analyze:
    #!/usr/bin/env python3
    print("Has .py extension")
```

### No Exit Message

```just
[no-exit-message]
check:
    test -f config.toml
```

### Default Recipe

```just
[default]
all: build test
```

## Shebang Recipes

Execute as a script file:

```just
# Python
analyze:
    #!/usr/bin/env python3
    import sys
    print(f"Python {sys.version}")

# Bash with strict mode
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Strict bash"

# Node.js
bundle:
    #!/usr/bin/env node
    console.log("Bundling...");

# Ruby
generate:
    #!/usr/bin/env ruby
    puts "Generating..."
```

## Line Prefixes

```just
build:
    # @ suppresses echoing this line
    @echo "Building..."

    # - continues on error
    -rm old-file.txt

    cargo build
```

## Aliases

```just
alias b := build
alias t := test

build:
    cargo build

test:
    cargo test
```

Alias to module recipe:

```just
alias db := database::migrate
```

## Combining Attributes

```just
[group('deploy')]
[confirm("Deploy to production?")]
[doc("Deploy the application to production")]
deploy-prod: build test
    ./deploy.sh production
```
