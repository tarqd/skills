---
name: using-kickstart
description: Use kickstart to scaffold new projects from templates. Use when the user wants to generate a project from a kickstart template, run kickstart commands, use kickstart CLI, or scaffold from a template repository.
---

# Using Kickstart

Kickstart is a CLI scaffolding tool that generates projects from templates. It uses Tera templating (Jinja2-inspired) and supports local directories or Git repositories as template sources.

## Quick Start

```bash
# From local template
kickstart /path/to/template

# From Git repository
kickstart https://github.com/user/template-repo

# Specify output directory
kickstart template -o MyProject

# Use subdirectory within a repo (for repos with multiple templates)
kickstart https://github.com/user/repo -d templates/rust-cli
```

## CLI Options

| Option | Short | Description |
|--------|-------|-------------|
| `--output-dir` | `-o` | Output directory (default: current directory) |
| `--directory` | `-d` | Subdirectory within template/repo to use |
| `--no-input` | | Use defaults without prompting |
| `--input-file` | `-i` | JSON file with variable values (implies --no-input) |
| `--run-hooks` | | Whether to run pre/post hooks (default: true) |

## Non-Interactive Generation

Create a JSON file with variable values:

```json
{
  "project_name": "my-app",
  "author": "Your Name",
  "use_docker": true
}
```

Then run:

```bash
kickstart template -i values.json -o output_dir
```

## Validating Templates

Check if a template is valid before using it:

```bash
kickstart validate /path/to/template.toml
```

## Common Workflows

### Scaffold from GitHub

```bash
# Clone and scaffold in one command
kickstart https://github.com/Keats/kickstart -d examples/complex -o MyProject
```

### Answer Questions Interactively

Just run kickstart and answer the prompts:

```bash
kickstart my-template
# ? Project name: my-app
# ? Author: Your Name
# ? Use Docker? yes
```

### Batch Generate Multiple Projects

Create different input files and generate:

```bash
kickstart template -i project1.json -o project1
kickstart template -i project2.json -o project2
```

## Tips

- Use `--no-input` when you want all defaults
- The `-d` flag is useful for monorepos with multiple templates
- JSON input files must have keys matching template variable names
- Values in JSON must match expected types (string, number, boolean)
