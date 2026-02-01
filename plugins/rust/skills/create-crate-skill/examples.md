# Example Crate Skills

Examples of skills created for Rust crates.

## Example: Kickstart Skill

We created a skill for the `kickstart` scaffolding tool:

**Structure:**
```
skills/kickstart/
├── creating-kickstart-templates/
│   ├── SKILL.md
│   ├── reference.md      # template.toml schema
│   ├── tera-syntax.md    # Templating reference
│   └── examples.md       # Example templates
└── using-kickstart/
    └── SKILL.md          # CLI usage
```

**Process used:**
1. Read `~/src/github.com/Keats/kickstart/`
2. Generated docs with `cargo doc --no-deps`
3. Read `target/doc/kickstart/index.html`
4. Studied `examples/` directory
5. Created two skills (usage + authoring)

## Example: Clap CLI Skill

For a CLI argument parsing crate:

**SKILL.md:**
```markdown
---
name: clap-cli
description: Use clap for command-line argument parsing. Use when building CLIs, parsing arguments, creating subcommands, or defining CLI flags and options in Rust.
---

# Clap CLI

Clap is a command-line argument parser for Rust.

## Quick Start

\`\`\`rust
use clap::Parser;

#[derive(Parser)]
#[command(name = "myapp")]
#[command(about = "Does awesome things")]
struct Cli {
    /// Name to greet
    #[arg(short, long)]
    name: String,

    /// Number of times to greet
    #[arg(short, long, default_value_t = 1)]
    count: u8,
}

fn main() {
    let cli = Cli::parse();
    for _ in 0..cli.count {
        println!("Hello {}!", cli.name);
    }
}
\`\`\`

## Core Concepts

### Derive vs Builder

- **Derive** (recommended): Use `#[derive(Parser)]` on structs
- **Builder**: Use `Command::new()` for dynamic CLIs

### Arguments vs Options

- **Arguments**: Positional, required by default
- **Options**: Named with `-` or `--`, optional by default

## Common Patterns

### Subcommands

\`\`\`rust
#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Add { name: String },
    Remove { name: String },
}
\`\`\`

### Value Validation

\`\`\`rust
#[arg(value_parser = clap::value_parser!(u16).range(1..=65535))]
port: u16,
\`\`\`

## Quick Links

- [Reference](reference.md)
- [Examples](examples.md)
```

## Example: Serde Skill

For serialization:

**SKILL.md:**
```markdown
---
name: serde-serialization
description: Use serde for serialization and deserialization. Use when parsing JSON, TOML, YAML, or other formats, or when defining serializable data structures in Rust.
---

# Serde Serialization

Serde is Rust's serialization/deserialization framework.

## Quick Start

\`\`\`rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct Config {
    name: String,
    count: u32,
    #[serde(default)]
    optional: Option<String>,
}

// Deserialize from JSON
let config: Config = serde_json::from_str(json_str)?;

// Serialize to JSON
let json = serde_json::to_string_pretty(&config)?;
\`\`\`

## Format Crates

| Format | Crate | Feature |
|--------|-------|---------|
| JSON | `serde_json` | - |
| TOML | `toml` | - |
| YAML | `serde_yaml` | - |
| Binary | `bincode` | - |

## Common Attributes

\`\`\`rust
#[derive(Serialize, Deserialize)]
struct Example {
    #[serde(rename = "type")]      // Field renaming
    kind: String,

    #[serde(default)]              // Use Default if missing
    count: u32,

    #[serde(skip_serializing_if = "Option::is_none")]
    optional: Option<String>,

    #[serde(flatten)]              // Flatten nested struct
    metadata: Metadata,
}
\`\`\`
```

## Example: Binary Tool (ripgrep)

For a binary crate:

**SKILL.md:**
```markdown
---
name: ripgrep
description: Use ripgrep (rg) for fast text searching. Use when searching files, finding patterns in codebases, or grep-like operations that need speed and smart defaults.
---

# Ripgrep

Ripgrep is a line-oriented search tool that recursively searches directories.

## Quick Start

\`\`\`bash
# Search for pattern in current directory
rg "pattern"

# Search specific file types
rg "pattern" -t rust

# Search with context
rg "pattern" -C 3
\`\`\`

## Common Options

| Option | Description |
|--------|-------------|
| `-i` | Case insensitive |
| `-w` | Word boundaries |
| `-t TYPE` | File type filter |
| `-g GLOB` | Glob pattern |
| `-C NUM` | Context lines |
| `-l` | List files only |
| `--json` | JSON output |

## Patterns

\`\`\`bash
# Regex
rg "fn\s+\w+"

# Fixed string (faster)
rg -F "exact match"

# Multiline
rg -U "start.*\n.*end"
\`\`\`

## Integration

\`\`\`rust
// Using ripgrep as a library (grep crate)
use grep::regex::RegexMatcher;
use grep::searcher::Searcher;
\`\`\`
```

## Skill Creation Checklist

When creating a crate skill:

1. **Identify the crate type:**
   - Library → Focus on API and types
   - Binary → Focus on CLI usage
   - Both → Create separate skills or sections

2. **Essential sections:**
   - Quick start with working code
   - Core concepts explained
   - Common patterns/recipes
   - Links to detailed reference

3. **Reference file should have:**
   - All public types with key methods
   - Function signatures
   - Error types
   - Feature flags

4. **Examples file should have:**
   - Real-world usage from examples/
   - Error handling patterns
   - Integration with common crates
