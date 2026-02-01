# tarq

A personal collection of Claude Code plugins by Chris Tarquini.

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
/plugin marketplace add tarqd/skills

# Install a plugin
/plugin install kickstart@tarq
```

Or install from a local clone:

```bash
git clone https://github.com/tarqd/skills.git
cd skills

# Add local marketplace
claude plugin marketplace add ./
# skills will  be available via /plugin command 
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

### Local Development

#### Testing with `--plugin-dir`

The fastest way to test a plugin during development is using the `--plugin-dir` flag:

```bash
# Test a plugin directly without installing
claude --plugin-dir ./plugins/my-plugin

# Test multiple plugins
claude --plugin-dir ./plugins/kickstart --plugin-dir ./plugins/rust
```

This loads the plugin directly from the directory, so changes take effect immediately on the next session.

#### Using Local Marketplace

Alternatively, add the marketplace locally for a more production-like setup:

```bash
# Clone and enter the repo
git clone https://github.com/tarqd/skills.git
cd skills

# Add as local marketplace
/plugin marketplace add ./

# Install a plugin you're working on
/plugin install my-plugin@tarq

# After making changes, reinstall to pick them up
/plugin uninstall my-plugin@tarq
/plugin install my-plugin@tarq
```

### Validation

```bash
just validate            # Run all validations
just validate-schemas    # Validate JSON schemas
just validate-templates  # Validate kickstart templates
```

## Using the Kickstart Templates

The templates can be used standalone to scaffold Claude Code plugins anywhere.

### Install Kickstart

```bash
# macOS
brew install kickstart

# Or see https://github.com/Keats/kickstart
```

### Available Templates

| Template | Description |
|----------|-------------|
| `claude-plugin` | Full plugin with empty component directories |
| `claude-skill` | Skill with SKILL.md, reference.md, examples.md |
| `claude-agent` | Standalone agent file |
| `claude-hook` | Hook configuration with shell script |

### Usage

```bash
# Clone the templates
git clone https://github.com/tarqd/skills.git
cd skills

# Create a new plugin anywhere
kickstart templates/claude-plugin -o ~/my-projects/

# Add a skill to any plugin
kickstart templates/claude-skill -o ~/my-projects/my-plugin/skills/

# Add an agent
kickstart templates/claude-agent -o ~/my-projects/my-plugin/agents/

# Add hooks
kickstart templates/claude-hook -o ~/my-projects/my-plugin/hooks/
```

Each template prompts for configuration interactively. Use `--no-input` to accept defaults:

```bash
kickstart skills/templates/claude-plugin -o ./ --no-input
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
