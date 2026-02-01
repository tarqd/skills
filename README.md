# Claude Code Plugin Marketplace Template

Create and distribute Claude Code plugins for your team or community. This GitHub template provides everything you need to build a plugin marketplace — from scaffolding and validation to CI/CD automation.

[![GitHub stars](https://img.shields.io/github/stars/ivan-magda/claude-code-plugin-template?style=social)](https://github.com/ivan-magda/claude-code-plugin-template/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ivan-magda/claude-code-plugin-template?style=social)](https://github.com/ivan-magda/claude-code-plugin-template/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Validate Plugins](https://github.com/ivan-magda/claude-code-plugin-template/actions/workflows/validate-plugins.yml/badge.svg)](https://github.com/ivan-magda/claude-code-plugin-template/actions/workflows/validate-plugins.yml)

## Why Use This Template?

- **Skip the boilerplate** — Pre-configured marketplace structure, plugin manifests, and GitHub Actions validation
- **Full plugin development toolkit** — Commands for scaffolding plugins, adding components (commands, skills, agents, hooks), and validating before release
- **Team-ready distribution** — Configure automatic marketplace installation for team projects
- **Best practices built-in** — Comprehensive documentation, examples, and guided workflows

## What's Included

| Component | Description |
|-----------|-------------|
| **Marketplace Configuration** | `.claude-plugin/marketplace.json` following the [official schema](https://code.claude.com/docs/en/plugin-marketplaces#marketplace-schema) |
| **Kickstart Templates** | Scaffold plugins, skills, agents, and hooks with `just new-plugin`, `just add-skill`, etc. |
| **Plugin Development Toolkit** | `plugin-development` plugin with slash commands, a `plugin-authoring` skill, and a reviewer agent |
| **CI/CD Workflows** | GitHub Actions for automated validation on every push and PR |
| **Documentation** | Complete guides for plugins, hooks, settings, commands, skills, and sub-agents |

## Quick Start

### 1. Create Your Marketplace

Click **"Use this template"** on GitHub, then clone your new repository:

```bash
git clone https://github.com/your-org/your-marketplace-name.git
cd your-marketplace-name
```

### 2. Customize the Marketplace

Update `.claude-plugin/marketplace.json` with your organization details:

```json
{
  "name": "my-team-marketplace",
  "owner": {
    "name": "Your Organization",
    "email": "team@your-org.com"
  },
  "metadata": {
    "description": "A curated collection of Claude Code plugins for our team",
    "version": "1.0.0"
  },
  "plugins": []
}
```

### 3. Install the Plugin Development Toolkit

```bash
# Start Claude Code
claude

# Add your local marketplace
/plugin marketplace add .

# Install the development toolkit
/plugin install plugin-development@my-team-marketplace
```

### 4. Create Your First Plugin

```bash
# Scaffold a new plugin
/plugin-development:init my-awesome-plugin

# Add components
/plugin-development:add-command my-command "Description of what it does"
/plugin-development:add-skill my-skill "Use when working with..."

# Validate before publishing
/plugin-development:validate
```

## Plugin Development Commands

The `plugin-development` plugin provides these commands:

| Command | Description |
|---------|-------------|
| `/plugin-development:init [name]` | Scaffold a new plugin with standard structure |
| `/plugin-development:add-command [name] [desc]` | Add a new slash command |
| `/plugin-development:add-skill [name] [desc]` | Add a new skill with SKILL.md |
| `/plugin-development:add-agent [name] [desc]` | Add a new sub-agent |
| `/plugin-development:add-hook [event] [matcher]` | Add a hook configuration |
| `/plugin-development:validate` | Validate plugin structure and configuration |
| `/plugin-development:test-local` | Create dev marketplace for local testing |

## Repository Structure

```
├── .claude-plugin/
│   └── marketplace.json          # Marketplace configuration
├── .github/workflows/
│   └── validate-plugins.yml      # CI/CD validation
├── ci/                           # Validation scripts
│   ├── validate-schemas.sh
│   ├── validate-structure.sh
│   ├── validate-templates.sh
│   └── check-duplicates.sh
├── templates/                    # Kickstart templates
│   ├── claude-plugin/            # Full plugin scaffold
│   ├── claude-skill/             # Skill template
│   ├── claude-agent/             # Agent template
│   └── claude-hook/              # Hook template
├── docs/                         # Documentation
├── plugins/                      # Your plugins
│   └── plugin-development/       # Development toolkit
├── Justfile                      # Task runner recipes
└── schemas/                      # JSON schemas
```

## Team Distribution

Configure automatic marketplace installation for your team by adding `.claude/settings.json` to your projects:

```json
{
  "extraKnownMarketplaces": {
    "my-team-marketplace": {
      "source": {
        "source": "github",
        "repo": "your-org/your-marketplace-name"
      }
    }
  }
}
```

When team members trust the repository folder, Claude Code automatically installs the marketplace. See [Configure team marketplaces](https://code.claude.com/docs/en/plugin-marketplaces#configure-team-marketplaces) for details.

## Installing from GitHub

Once your marketplace is published to GitHub, users can install plugins with:

```bash
# Add the marketplace
/plugin marketplace add your-org/your-marketplace-name

# Install a plugin
/plugin install plugin-name@your-marketplace-name
```

## Local Testing

Test your plugins before publishing:

```bash
# Navigate to your marketplace
cd your-marketplace-name

# Start Claude Code
claude

# Add local marketplace
/plugin marketplace add .

# Install and test a plugin
/plugin install hello-world@my-team-marketplace
/hello World
```

For iterative development:

```bash
# After making changes
/plugin-development:validate
/plugin uninstall plugin-name@my-team-marketplace
/plugin install plugin-name@my-team-marketplace
```

## Uninstalling

Remove the marketplace and its plugins from Claude Code:

```bash
# Remove a specific plugin
/plugin uninstall plugin-name@my-team-marketplace

# Remove the marketplace entirely
/plugin marketplace remove my-team-marketplace
```

To completely remove, delete the cloned repository directory.

## Scaffolding with Kickstart Templates

This repository includes [kickstart](https://github.com/Keats/kickstart) templates for scaffolding plugins and components.

### Prerequisites

```bash
# Install dependencies (macOS)
just setup
```

### Create a New Plugin

```bash
just new-plugin
```

This prompts for plugin details, creates the plugin structure, and registers it in `marketplace.json`.

### Add Components to a Plugin

```bash
just add-skill rust      # Add a skill to the rust plugin
just add-agent rust      # Add an agent to the rust plugin
just add-hook rust       # Add a hook to the rust plugin

# Or run interactively (lists available plugins)
just add-skill
```

### Available Recipes

```bash
just                     # Show all available recipes
```

| Recipe | Description |
|--------|-------------|
| `just setup` | Install dependencies via Homebrew |
| `just new-plugin` | Create a new plugin and register in marketplace |
| `just add-skill [plugin]` | Add a skill to a plugin |
| `just add-agent [plugin]` | Add an agent to a plugin |
| `just add-hook [plugin]` | Add a hook to a plugin |
| `just validate` | Run all validations |
| `just ci` | CI entrypoint (runs all validations) |

### Kickstart Templates

Templates are in the `templates/` directory:

| Template | Description |
|----------|-------------|
| `claude-plugin` | Full plugin with empty component directories |
| `claude-skill` | Skill with SKILL.md, reference.md, examples.md |
| `claude-agent` | Standalone agent file |
| `claude-hook` | Hook configuration with shell script |

Use templates directly with kickstart:

```bash
kickstart templates/claude-skill -o plugins/my-plugin/skills
```

## Creating Plugins Manually

If you prefer manual setup:

### 1. Create Plugin Directory

```bash
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/{skills,commands,agents,hooks}
```

### 2. Add Plugin Manifest

Create `plugins/my-plugin/.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Description of what your plugin does",
  "author": { "name": "Your Name" },
  "license": "MIT"
}
```

### 3. Register in Marketplace

Add to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "category": "utilities",
      "tags": ["tag1", "tag2"]
    }
  ]
}
```

## Documentation

### Local Guides (in `docs/`)

| Guide | Description |
|-------|-------------|
| [Plugin Development](docs/plugins.md) | Complete guide to creating plugins |
| [Plugin Reference](docs/plugins-reference.md) | Technical specifications and schemas |
| [Plugin Marketplaces](docs/plugin-marketplaces.md) | Marketplace creation and management |
| [Hooks](docs/hooks.md) | Event-driven automation |
| [Settings](docs/settings.md) | Configuration and customization |
| [Slash Commands](docs/slash-commands.md) | Command system reference |
| [Skills](docs/skills.md) | Agent capabilities and expertise |
| [Sub-Agents](docs/sub-agents.md) | Specialized AI assistants |

### Official Claude Code Documentation

- [Plugins Overview](https://code.claude.com/docs/en/plugins) — Plugin development guide
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) — Marketplace management
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference) — Technical specifications
- [Slash Commands](https://code.claude.com/docs/en/slash-commands) — Command development

## Example Plugins

### hello-world

A minimal example demonstrating proper plugin structure:

```bash
/plugin install hello-world@my-team-marketplace
/hello World
# Output: Hello, World! 👋
```

### plugin-development

The comprehensive toolkit used throughout this template:

- **7 slash commands** for scaffolding and validation
- **plugin-authoring skill** for ambient guidance
- **plugin-reviewer agent** for release readiness audits
- **Automated hooks** for validation and formatting

See the [plugin-development README](plugins/plugin-development/README.md) for complete documentation.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-plugin`)
3. Make your changes
4. Run validation (`/plugin-development:validate`)
5. Commit your changes (`git commit -m 'Add amazing plugin'`)
6. Push to the branch (`git push origin feature/amazing-plugin`)
7. Open a Pull Request

## Acknowledgments

Built for [Claude Code](https://claude.com/claude-code) by [Anthropic](https://www.anthropic.com/).

## License

MIT License — see [LICENSE](LICENSE) for details.

## Resources

- [Claude Code Documentation](https://code.claude.com/docs)
- [Anthropic Discord](https://discord.com/invite/anthropic) — Community support
- [Claude Code GitHub](https://github.com/anthropics/claude-code) — Official repository
