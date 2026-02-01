---
name: using-just
description: Use the just command runner to execute recipes. Use when running just commands, listing recipes, choosing recipes interactively, evaluating variables, or using just CLI features.
---

# Using Just

Just is a command runner that executes recipes defined in a `justfile`.

## Quick Start

```bash
# Run default recipe
just

# Run specific recipe
just build

# Run with arguments
just test integration

# Run multiple recipes
just clean build test
```

## Listing Recipes

```bash
# List all recipes with descriptions
just --list

# List in file order (not alphabetical)
just --list --unsorted

# List with groups shown
just --list --groups

# One-line summary
just --summary

# Show recipe groups
just --groups
```

## Running Recipes

```bash
# Run recipe from specific justfile
just -f path/to/justfile recipe

# Run from different directory
just -d /path/to/project recipe

# Set variables from CLI
just --set version "1.0.0" release

# Dry run (show commands without executing)
just --dry-run build

# Run without dependencies
just --no-deps test

# Run only one recipe (stop after first)
just -1 test1 test2
```

## Interactive Mode

```bash
# Choose recipe interactively (requires fzf)
just --choose

# Use custom chooser
just --choose --chooser "fzf --multi"

# Auto-confirm prompts
just --yes dangerous-recipe
```

## Inspecting Justfiles

```bash
# Show recipe source
just --show build

# Show recipe usage
just --usage deploy

# Evaluate and print variables
just --evaluate
just --evaluate version

# List all variables
just --variables

# Dump parsed justfile
just --dump
just --dump --dump-format json
just --dump --dump-format yaml
```

## Working with Modules

```bash
# Run recipe from module
just module::recipe
just module recipe

# List module recipes
just --list module::
```

## Editing & Setup

```bash
# Edit justfile in $EDITOR
just --edit

# Create starter justfile
just --init

# Format justfile (unstable)
just --fmt

# Check justfile syntax
just --check
```

## Shell Completions

```bash
# Generate completions
just --completions bash > just.bash
just --completions zsh > _just
just --completions fish > just.fish
just --completions powershell > just.ps1
```

## Common Options

| Option | Short | Description |
|--------|-------|-------------|
| `--justfile FILE` | `-f` | Use specific justfile |
| `--directory DIR` | `-d` | Change to directory first |
| `--working-directory DIR` | `-C` | Set recipe working directory |
| `--dry-run` | `-n` | Show commands without running |
| `--quiet` | `-q` | Suppress output |
| `--verbose` | `-v` | Increase verbosity |
| `--color MODE` | | auto, always, or never |
| `--yes` | `-y` | Auto-confirm prompts |
| `--unstable` | | Enable unstable features |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `JUST_CHOOSER` | Default chooser for `--choose` |
| `JUST_UNSTABLE` | Enable unstable features |

## Tips

- Just searches upward for justfiles, so you can run from subdirectories
- Use `just --list` frequently to see available recipes
- The `--dry-run` flag is useful for testing complex recipes
- `just --show recipe` reveals the actual commands
