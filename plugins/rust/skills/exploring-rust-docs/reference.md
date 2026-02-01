# Cargo Doc HTML Structure Reference

## Directory Layout

After running `cargo doc`, documentation is generated at:

```
target/doc/
├── {crate_name}/           # Main crate docs
│   ├── index.html          # Crate overview
│   ├── all.html            # All items list
│   ├── struct.Foo.html     # Struct documentation
│   ├── enum.Bar.html       # Enum documentation
│   ├── trait.Baz.html      # Trait documentation
│   ├── fn.helper.html      # Function documentation
│   ├── type.Alias.html     # Type alias documentation
│   ├── constant.VALUE.html # Constant documentation
│   ├── macro.my_macro.html # Macro documentation
│   └── {submodule}/        # Submodule directory
│       ├── index.html
│       └── ...
├── src/                    # Source code viewer
│   └── {crate_name}/
│       └── {file}.rs.html
└── search-index.js         # Search functionality
```

## Reading HTML Documentation

### Crate Index (index.html)

The main entry point contains:

1. **Crate documentation** - The `//!` doc comments from `lib.rs`
2. **Modules section** - Links to submodules
3. **Structs section** - Public structs
4. **Enums section** - Public enums
5. **Traits section** - Public traits
6. **Functions section** - Public functions
7. **Type Aliases** - Type definitions
8. **Constants** - Public constants

Look for these HTML patterns:
```html
<section id="modules" class="section-header">
<section id="structs" class="section-header">
<section id="enums" class="section-header">
```

### Struct Documentation (struct.{Name}.html)

Contains:
- **Description** - Doc comments for the struct
- **Fields** - For non-tuple structs (id="fields")
- **Implementations** - impl blocks (id="implementations")
- **Trait Implementations** - impl Trait for Struct (id="trait-implementations")
- **Auto Trait Implementations** - Send, Sync, etc.

Key sections to grep for:
```
id="fields"
id="implementations"
id="trait-implementations"
class="impl"
class="method"
```

### Trait Documentation (trait.{Name}.html)

Contains:
- **Required Methods** - Methods implementors must define
- **Provided Methods** - Methods with default implementations
- **Implementors** - Types that implement this trait

Look for:
```
id="required-methods"
id="provided-methods"
id="implementors"
```

### Enum Documentation (enum.{Name}.html)

Contains:
- **Variants** - All enum variants with docs
- **Implementations** - Methods on the enum
- **Trait Implementations**

### Function Documentation (fn.{Name}.html)

Contains:
- **Signature** - Full function signature
- **Documentation** - Doc comments
- **Examples** - Code examples if provided

## Extracting Information

### Finding the Main Purpose

Read the first few sections of `index.html`:
```bash
# The crate description is usually in the first docblock
```

### Listing Public API

The `all.html` file contains everything:
- All structs, enums, traits, functions
- Organized alphabetically
- Useful for searching specific item names

### Finding Examples in Documentation

Examples are in `<pre class="rust">` blocks:
```html
<div class="example-wrap">
<pre class="rust rust-example-rendered">
```

### Finding Method Signatures

Methods have this structure:
```html
<section id="method.method_name" class="method">
<h4 class="code-header">
  fn method_name(&self, arg: Type) -> ReturnType
</h4>
```

## Common Grep Patterns

```bash
# Find all public structs
grep -r "struct\." target/doc/crate_name/*.html

# Find all methods on a type
grep "id=\"method\." target/doc/crate_name/struct.Foo.html

# Find examples
grep -A 20 "example-wrap" target/doc/crate_name/index.html

# Find trait implementations
grep "impl.*for.*Foo" target/doc/crate_name/struct.Foo.html
```

## Binary Crate Documentation

For binary crates (`src/main.rs`):

1. **No generated docs** - Binaries don't get doc HTML by default
2. **Check for lib.rs** - Many binaries have a library component
3. **Read source directly** - `src/main.rs`, `src/cli.rs`
4. **Look for CLI parsing** - clap, structopt, argh argument definitions
5. **Check README** - Often has usage examples

For clap-based CLIs:
```bash
# Find command definitions
grep -r "command\|subcommand\|arg\|Arg::" src/
```

## Workspace Documentation

For workspaces with multiple crates:

```bash
# Document all workspace members
cargo doc --workspace --no-deps

# Document specific member
cargo doc -p member_crate --no-deps
```

Each member gets its own directory in `target/doc/`.

## Tips for Reading Docs

1. **Start with index.html** - Get the big picture
2. **Check all.html** - Find specific items quickly
3. **Read trait docs** - Understand behavior contracts
4. **Look at examples/** - Real usage patterns
5. **Check tests/** - Additional usage examples
6. **Read src/ for details** - When docs are insufficient
