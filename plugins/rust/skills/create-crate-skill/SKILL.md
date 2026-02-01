---
name: create-crate-skill
description: Create Claude skills for Rust crates and binaries. Use when the user wants to create a skill for a Rust crate, document a Rust library for Claude, make a skill from cargo docs, or create a skill to help use a Rust tool or binary.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Create Crate Skill

This skill guides the creation of Claude skills for Rust crates and binaries. It integrates with the `exploring-rust-docs` skill and the `plugin-dev:skill-development` skill.

## When to Activate

- User wants to create a skill for a Rust crate
- User wants Claude to understand how to use a Rust library
- User wants to document a Rust binary/CLI tool as a skill
- Creating skills based on cargo-generated documentation

## Prerequisites

This skill works alongside:
- **exploring-rust-docs** - For reading cargo doc HTML
- **plugin-dev:skill-development** - For skill structure and best practices

## Workflow

### 1. Locate the Crate Source

**For dependencies in Cargo.toml:**
```bash
# Check if source is available
ls ~/.cargo/registry/src/*/crate_name-*

# Or check if cloned locally
ls ~/src/**/crate_name
```

**For standalone repos, ask the user:**
- Do you have the source cloned locally?
- What directory is it in?
- Should I clone it for you?

### 2. Generate and Explore Documentation

Use the `exploring-rust-docs` skill:

```bash
cd /path/to/crate
cargo doc --no-deps  # NEVER use --open
```

Read the key documentation files:
- `target/doc/{crate}/index.html` - Overview
- `target/doc/{crate}/all.html` - All items
- Main struct/trait pages

### 3. Find and Review Examples

```bash
# Check for examples directory
ls examples/

# Read example files
cat examples/*.rs

# Check for integration tests with examples
ls tests/
```

### 4. Identify Key Components

Document these for the skill:
- **Primary types** - Main structs, enums, traits
- **Entry points** - How users start using the crate
- **Common patterns** - Typical usage flows
- **Configuration** - Builder patterns, options
- **Error handling** - Error types, Result patterns

### 5. Create the Skill Structure

```
skills/{crate-name}/
├── SKILL.md           # Main skill file
├── reference.md       # API reference
├── examples.md        # Usage examples
└── patterns.md        # Common patterns (optional)
```

### 6. Write the Skill

Follow the template in [workflow.md](workflow.md).

**Key sections:**
- When to use this crate
- Quick start example
- Core concepts
- Common operations
- Links to reference files

## Quick Links

- [Workflow Details](workflow.md)
- [Example Skills](examples.md)

## For Binary Crates

Binary crates require different handling:

1. **Check for local clone:**
   ```bash
   # Ask user or search common locations
   ls ~/src/**/binary_name
   ```

2. **If not available, offer to clone:**
   ```bash
   git clone https://github.com/user/repo ~/src/github.com/user/repo
   ```

3. **Read source directly:**
   - `src/main.rs` - Entry point
   - `src/cli.rs` or similar - Argument parsing
   - Look for clap/structopt/argh definitions

4. **Check README and docs:**
   - Usage examples
   - Command-line options
   - Configuration files

5. **Run help if possible:**
   ```bash
   cargo run -- --help
   ```

## Integration with plugin-dev

After gathering information, use `/plugin-dev:add-skill` or manually create:

1. Create skill directory in appropriate plugin
2. Write SKILL.md with frontmatter
3. Add reference files
4. Validate with `/plugin-dev:validate`

## Notes

- Always use `cargo doc --no-deps` (never `--open`)
- Prefer reading examples/ over just API docs
- For complex crates, focus on the 80% use case
- Include real code examples in the skill
- Link to official docs for comprehensive reference
