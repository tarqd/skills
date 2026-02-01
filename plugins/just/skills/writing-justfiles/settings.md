# Settings Reference

Settings configure justfile behavior. Place at the top of your justfile.

## Shell Configuration

```just
# Set shell (default: sh -cu on Unix)
set shell := ["bash", "-uc"]

# Windows-specific shell
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

# Script interpreter for [script] recipes
set script-interpreter := ['python3']
```

## Dotenv

```just
# Load .env file
set dotenv-load

# Custom .env filename
set dotenv-filename := ".env.local"

# Custom .env path
set dotenv-path := "config/.env"

# Error if .env missing
set dotenv-required

# Override existing env vars with .env values
set dotenv-override
```

## Variable Export

```just
# Export all variables as environment variables
set export

# Then all variables are available in recipes:
version := "1.0.0"

build:
    echo $version  # Works!
```

## Output Control

```just
# Suppress command echoing (like @ prefix everywhere)
set quiet

# Ignore comments in recipes (don't echo them)
set ignore-comments
```

## Duplicate Handling

```just
# Allow duplicate recipe names (last wins)
set allow-duplicate-recipes

# Allow duplicate variable names (last wins)
set allow-duplicate-variables
```

## Working Directory

```just
# Set working directory for all recipes
set working-directory := "src"

# Custom temp directory for shebang scripts
set tempdir := "/tmp/just"
```

## Fallback

```just
# Search parent directories for justfiles
set fallback
```

When a recipe isn't found, just searches parent directories.

## Positional Arguments

```just
# Pass arguments as positional to shell
set positional-arguments

@test *args:
    echo "$@"       # All arguments
    echo "$1"       # First argument
```

## Unstable Features

```just
# Enable unstable features
set unstable
```

Required for features like `&&`/`||` operators, `--fmt`, etc.

## All Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `allow-duplicate-recipes` | `false` | Allow duplicate recipe names |
| `allow-duplicate-variables` | `false` | Allow duplicate variable names |
| `dotenv-filename` | `.env` | Name of dotenv file |
| `dotenv-load` | `false` | Load .env file |
| `dotenv-override` | `false` | .env overrides environment |
| `dotenv-path` | - | Path to .env file |
| `dotenv-required` | `false` | Error if .env missing |
| `export` | `false` | Export all variables |
| `fallback` | `false` | Search parent justfiles |
| `ignore-comments` | `false` | Don't echo comments |
| `positional-arguments` | `false` | Use positional args in shell |
| `quiet` | `false` | Suppress echoing |
| `script-interpreter` | `['sh', '-eu']` | Interpreter for [script] |
| `shell` | `['sh', '-cu']` | Shell for recipes |
| `tempdir` | system temp | Temp dir for scripts |
| `unstable` | `false` | Enable unstable features |
| `windows-shell` | `['cmd', '/c']` | Windows shell |
| `working-directory` | justfile dir | Recipe working directory |

## Examples

### Development Setup

```just
set dotenv-load
set export
set quiet

version := env('VERSION', '0.0.0')
```

### Cross-Platform

```just
set shell := ["bash", "-uc"]
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

build:
    echo "Building..."
```

### Strict Mode

```just
set shell := ["bash", "-euo", "pipefail", "-c"]

# Recipes fail on:
# -e: any command error
# -u: undefined variables
# -o pipefail: pipe failures
```

### Monorepo

```just
set fallback
set working-directory := "packages/core"

build:
    npm run build
```
