---
name: exploring-rust-docs
description: Explore and understand Rust crates via cargo doc generated HTML documentation. Use when the user wants to understand a Rust crate, read crate documentation, explore module structure, find traits/structs/functions, or learn how a Rust library works.
allowed-tools: Read, Grep, Glob, Bash
---

# Exploring Rust Documentation

This skill helps you explore and understand Rust crates by reading their cargo-generated HTML documentation.

## When to Activate

- User wants to understand a Rust crate or library
- User asks about module structure, traits, structs, or functions in a crate
- User wants to explore a crate's API before using it
- Working with Rust code and need to understand dependencies

## Workflow

### 1. Locate or Generate Documentation

Check if docs exist, otherwise generate them:

```bash
# Check for existing docs
ls target/doc/

# Generate docs (NEVER use --open)
cargo doc --no-deps
```

For workspace members or specific crates:
```bash
cargo doc --no-deps -p crate_name
```

### 2. Find the Documentation Entry Point

The main index is at:
```
target/doc/{crate_name}/index.html
```

For crates with hyphens, the directory uses underscores:
```
target/doc/my_crate/index.html  # for my-crate
```

### 3. Navigate the Documentation Structure

See [reference.md](reference.md) for detailed HTML structure.

**Key files to read:**
- `index.html` - Crate overview, re-exports, modules list
- `all.html` - Complete list of all items
- `struct.{Name}.html` - Struct documentation
- `trait.{Name}.html` - Trait documentation
- `fn.{Name}.html` - Function documentation
- `enum.{Name}.html` - Enum documentation
- `{module}/index.html` - Module documentation

### 4. Extract Key Information

When reading doc HTML, look for:

1. **Crate purpose** - Top of index.html has the crate-level doc comment
2. **Main types** - Listed in "Structs", "Enums", "Traits" sections
3. **Public API** - Functions and methods in each type's page
4. **Examples** - Code blocks in documentation (look for `<pre class="rust">`)
5. **Feature flags** - Often documented in crate root or Cargo.toml

### 5. Check Examples Directory

Most crates include examples:
```bash
ls examples/
```

Read example files to understand real-world usage patterns.

## Quick Reference

| Item Type | File Pattern | Key Sections |
|-----------|--------------|--------------|
| Crate root | `index.html` | Modules, Structs, Enums, Traits, Functions |
| Module | `{mod}/index.html` | Same as crate root |
| Struct | `struct.{Name}.html` | Fields, Implementations, Trait Impls |
| Enum | `enum.{Name}.html` | Variants, Implementations |
| Trait | `trait.{Name}.html` | Required/Provided Methods, Implementors |
| Function | `fn.{Name}.html` | Signature, Documentation |

## Tips

- Use Grep to search across doc HTML for specific terms
- The `all.html` page is useful for finding items by name
- Source links in docs point to `src/{crate}/` for implementation details
- For binaries, check `src/main.rs` and any CLI argument parsing (clap, structopt)

## Quick Links

- [HTML Structure Reference](reference.md)
