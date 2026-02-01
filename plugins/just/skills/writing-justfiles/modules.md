# Modules & Imports Reference

## Imports

Import another file's content directly (flat, no namespace):

```just
import 'common.just'
import 'ci/build.just'

# Optional import (no error if missing)
import? 'local.just'
```

Imported recipes are available directly:

```just
# common.just
clean:
    rm -rf target/

# justfile
import 'common.just'

build: clean  # Can use clean directly
    cargo build
```

## Modules

Import with a namespace:

```just
mod build
mod test
mod deploy
```

### Module Resolution

Just looks for module files in this order:

1. `{name}.just`
2. `{name}/mod.just`
3. `{name}/justfile`
4. `{name}/.justfile`

```
project/
├── justfile
├── build.just           # mod build
├── test/
│   └── mod.just         # mod test
└── deploy/
    └── justfile         # mod deploy
```

### Custom Module Path

```just
mod build 'ci/build.just'
mod config 'config/recipes.just'
```

### Optional Modules

```just
mod? local  # No error if missing
```

## Using Module Recipes

### Subcommand Syntax

```bash
just build::release
just test::unit
just deploy::production
```

### Space Syntax

```bash
just build release
just test unit
just deploy production
```

## Module Features

### Default Recipe

Each module can have its own default:

```just
# build.just
[default]
all: debug release

debug:
    cargo build

release:
    cargo build --release
```

### Private Modules

Prefix with underscore or use attribute:

```just
mod _internal  # Hidden from --list

[private]
mod helpers
```

### Module Documentation

```just
# Build recipes for the project
mod build

[doc("Testing utilities")]
mod test
```

### Module Working Directory

Each module uses its directory as working directory:

```
project/
├── justfile
└── frontend/
    ├── mod.just      # Recipes run in frontend/
    └── package.json
```

```just
# frontend/mod.just
build:
    npm run build  # Runs in frontend/
```

## Aliases Across Modules

```just
alias b := build::release
alias t := test::unit
alias d := deploy::staging
```

## Dependencies Across Modules

```just
# justfile
mod build
mod test

release: build::release test::all
    echo "Ready for release"
```

## Module Settings

Modules can have their own settings:

```just
# frontend/mod.just
set shell := ["bash", "-c"]
set working-directory := "."

build:
    npm run build
```

## Practical Examples

### Monorepo Structure

```
monorepo/
├── justfile
├── packages/
│   ├── api/
│   │   └── mod.just
│   ├── web/
│   │   └── mod.just
│   └── shared/
│       └── mod.just
└── ci/
    └── mod.just
```

```just
# justfile
mod api 'packages/api/mod.just'
mod web 'packages/web/mod.just'
mod shared 'packages/shared/mod.just'
mod ci 'ci/mod.just'

default: shared::build api::build web::build

test: api::test web::test

deploy: ci::deploy
```

### Feature-Based Organization

```just
# justfile
mod build
mod test
mod lint
mod docs

[group('dev')]
dev: build::debug test::unit

[group('ci')]
ci: lint::all test::all build::release

[group('release')]
release: ci docs::build
    ./scripts/release.sh
```

### Shared Configuration

```just
# common.just (import, not module)
version := "1.0.0"
target := "x86_64-unknown-linux-gnu"

_check-env:
    @test -n "$CI" || echo "Warning: not in CI"

# justfile
import 'common.just'

mod build
mod deploy
```

## Tips

- Use `import` for shared variables and helper recipes
- Use `mod` for organized, namespaced recipe groups
- Modules are better for larger projects
- Imports are better for shared configuration
- Each module has its own scope for variables
- Modules can access parent justfile variables
- Use aliases for frequently-used module recipes
