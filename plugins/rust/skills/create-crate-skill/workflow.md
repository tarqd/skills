# Create Crate Skill Workflow

Step-by-step process for creating a skill from a Rust crate.

## Phase 1: Discovery

### Locate the Crate

```bash
# Option A: Local clone
ls ~/src/**/crate_name

# Option B: Cargo registry (for dependencies)
ls ~/.cargo/registry/src/*/crate_name-*

# Option C: Clone it
git clone https://github.com/user/crate_name ~/src/github.com/user/crate_name
```

### Generate Documentation

```bash
cd /path/to/crate
cargo doc --no-deps
```

### Initial Exploration

1. Read `target/doc/{crate}/index.html`
2. Identify the crate's purpose
3. List main types (structs, traits, enums)
4. Note the primary entry points

## Phase 2: Deep Dive

### Read Core Types

For each major type:
```bash
# Read struct documentation
cat target/doc/crate_name/struct.MainType.html
```

Extract:
- Purpose and description
- Key methods
- Builder patterns
- Common trait implementations

### Study Examples

```bash
# List examples
ls examples/

# Read each example
for f in examples/*.rs; do echo "=== $f ==="; cat "$f"; done
```

Note:
- Setup/initialization patterns
- Error handling approaches
- Common configurations

### Check Tests for Patterns

```bash
# Integration tests often show real usage
ls tests/
cat tests/*.rs
```

## Phase 3: Skill Creation

### Create Directory Structure

```bash
mkdir -p skills/{crate-name}
```

### Write SKILL.md

```markdown
---
name: {crate-name}
description: Use {crate_name} for {purpose}. Use when {triggers}.
---

# {Crate Name}

{Brief description from crate docs}

## Quick Start

\`\`\`rust
{minimal working example}
\`\`\`

## When to Use

- {Use case 1}
- {Use case 2}
- {Use case 3}

## Core Concepts

### {Main Type}

{Description and key methods}

### {Another Type}

{Description}

## Common Operations

### {Operation 1}

\`\`\`rust
{code example}
\`\`\`

### {Operation 2}

\`\`\`rust
{code example}
\`\`\`

## Quick Links

- [API Reference](reference.md)
- [Examples](examples.md)

## Notes

- {Important gotcha}
- {Best practice}
```

### Write reference.md

```markdown
# {Crate Name} Reference

## Types

### {StructName}

{Description}

**Key Methods:**
- `new()` - {description}
- `method_name(&self, arg: Type) -> Result` - {description}

### {EnumName}

**Variants:**
- `Variant1` - {description}
- `Variant2(T)` - {description}

## Traits

### {TraitName}

{Description}

**Required Methods:**
- `method(&self) -> Type`

## Functions

### `function_name`

\`\`\`rust
pub fn function_name(arg: Type) -> Result<T, E>
\`\`\`

{Description}

## Error Handling

{Error types and how to handle them}

## Feature Flags

- `feature1` - {what it enables}
- `feature2` - {what it enables}
```

### Write examples.md

```markdown
# {Crate Name} Examples

## Basic Usage

\`\`\`rust
{example from examples/ directory}
\`\`\`

## {Use Case}

\`\`\`rust
{another example}
\`\`\`

## Error Handling

\`\`\`rust
{example showing error handling}
\`\`\`

## With {Other Crate}

\`\`\`rust
{integration example if relevant}
\`\`\`
```

## Phase 4: Validation

### Check Skill Structure

```bash
# Verify files exist
ls skills/{crate-name}/

# Check frontmatter
head -10 skills/{crate-name}/SKILL.md
```

### Validate with plugin-dev

```
/plugin-dev:validate
```

### Test the Skill

1. Ask Claude about the crate
2. Verify skill activates
3. Check examples work
4. Validate reference links

## Checklist

```
□ Source located or cloned
□ cargo doc generated
□ index.html read and understood
□ Main types documented
□ Examples reviewed
□ SKILL.md written with frontmatter
□ reference.md with API details
□ examples.md with code samples
□ Validated with plugin-dev
□ Tested activation
```
