# tarq-code

A personal collection of Claude Code plugins by Chris Tarquini.

[![Validate Plugins](https://github.com/anthropics/claude-code/actions/workflows/validate-plugins.yml/badge.svg)](https://github.com/anthropics/claude-code/actions/workflows/validate-plugins.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Plugins

| Plugin | Description |
|--------|-------------|
| **[kickstart](plugins/kickstart)** | Skills for creating and using kickstart templates |
| **[rust](plugins/rust)** | Explore Rust documentation and create skills for crates |
| **[just](plugins/just)** | Write justfiles and use the just command runner |
| **[plugin-development](plugins/plugin-development)** | Toolkit for creating Claude Code plugins |

## Installation

```bash
# Add the marketplace
/plugin marketplace add tarq-code/skills

# Install a plugin
/plugin install kickstart@tarq-code
```

Or install from a local clone:

```bash
git clone https://github.com/tarq-code/skills.git
cd skills

# Add local marketplace
/plugin marketplace add .

# Install plugins
/plugin install kickstart@tarq-code
```

## Development

### Prerequisites

```bash
# Install dependencies (macOS)
just setup
```

### Create a New Plugin

```bash
just new-plugin
```

This prompts for plugin details, creates the structure, and registers it in `marketplace.json`.

### Add Components to a Plugin

```bash
just add-skill rust      # Add a skill to the rust plugin
just add-agent rust      # Add an agent
just add-hook rust       # Add a hook

# Or run interactively
just add-skill
```

### Available Recipes

```bash
just                     # Show all recipes
```

| Recipe | Description |
|--------|-------------|
| `just setup` | Install dependencies via Homebrew |
| `just new-plugin` | Create a new plugin and register in marketplace |
| `just add-skill [plugin]` | Add a skill to a plugin |
| `just add-agent [plugin]` | Add an agent to a plugin |
| `just add-hook [plugin]` | Add a hook to a plugin |
| `just validate` | Run all validations |
| `just ci` | CI entrypoint |

### Kickstart Templates

Templates in `templates/` for scaffolding:

| Template | Description |
|----------|-------------|
| `claude-plugin` | Full plugin with empty component directories |
| `claude-skill` | Skill with SKILL.md, reference.md, examples.md |
| `claude-agent` | Standalone agent file |
| `claude-hook` | Hook configuration with shell script |

Use directly:

```bash
kickstart templates/claude-skill -o plugins/my-plugin/skills
```

### Validation

```bash
just validate            # Run all validations
just validate-schemas    # Validate JSON schemas
just validate-templates  # Validate kickstart templates
```

## Repository Structure

```
├── .claude-plugin/
│   └── marketplace.json      # Marketplace configuration
├── plugins/                  # Plugins
│   ├── kickstart/
│   ├── rust/
│   ├── just/
│   └── plugin-development/
├── templates/                # Kickstart templates
│   ├── claude-plugin/
│   ├── claude-skill/
│   ├── claude-agent/
│   └── claude-hook/
├── ci/                       # Validation scripts
├── schemas/                  # JSON schemas
└── Justfile                  # Task runner
```

## License

MIT
