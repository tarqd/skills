# Variables Reference

## Assignment

```just
version := "1.0.0"
name := "myapp"
target := "release"
```

## Exported Variables

Available as environment variables in recipes:

```just
export DATABASE_URL := "postgres://localhost/mydb"
export RUST_BACKTRACE := "1"

test:
    cargo test  # Can access $DATABASE_URL
```

## String Types

### Single-Quoted (Raw)

No escape sequences:

```just
path := 'C:\Users\name'
regex := 'foo\d+bar'
```

### Double-Quoted (Escaped)

Supports escape sequences:

```just
message := "Hello\nWorld"
tab := "col1\tcol2"
quote := "She said \"hi\""
unicode := "Emoji: \u{1F600}"
```

Escape sequences: `\n`, `\r`, `\t`, `\\`, `\"`, `\u{XXXX}`

### Backtick (Command Output)

```just
git_hash := `git rev-parse --short HEAD`
date := `date +%Y-%m-%d`
user := `whoami`
```

### Indented Strings (Triple Quotes)

```just
message := '''
    This is a
    multiline string
    with preserved indentation
'''

escaped := """
    Line 1\n
    Line 2
"""
```

### Format Strings

```just
name := "world"
greeting := f'Hello, {{name}}!'
```

### Shell-Expanded Strings

```just
home := x'~'
config := x'$HOME/.config'
```

## Operators

### Concatenation

```just
full_name := first + " " + last
greeting := "Hello, " + name + "!"
```

### Path Joining

```just
config_file := config_dir / "app.toml"
src_path := base / "src" / "main.rs"
```

### Conditionals

```just
mode := if debug == "true" { "debug" } else { "release" }
flags := if os() == "windows" { "/W4" } else { "-Wall" }
```

### Comparison

```just
# Equality
is_release := if mode == "release" { "yes" } else { "no" }

# Inequality
needs_build := if version != old_version { "true" } else { "false" }

# Regex match
is_valid := if name =~ '^[a-z]+$' { "yes" } else { "no" }
```

### Logical (Unstable)

```just
set unstable

both := if a == "1" && b == "2" { "yes" } else { "no" }
either := if a == "1" || b == "2" { "yes" } else { "no" }
```

## Using Variables

In recipes, use double braces:

```just
version := "1.0.0"

build:
    echo "Building version {{version}}"
    cargo build --features "{{features}}"
```

In other variables:

```just
base := "myapp"
versioned := base + "-" + version
```

## Variable Scope

Variables are global to the justfile. Modules have their own scope but can access parent variables.

```just
# justfile
name := "app"

mod sub

# sub.just
# Can access {{name}} from parent
build:
    echo "Building {{name}}"
```

## Overriding Variables

From command line:

```bash
just --set version "2.0.0" build
```

Or as environment variables (with `set export`):

```bash
version=2.0.0 just build
```

## Constants

Built-in constants:

```just
# Path separators
path := dir + PATH_SEP + file        # / or \
env_path := path1 + PATH_VAR_SEP + path2  # : or ;

# Hex alphabets
random := choose(8, HEX)        # 0-9A-Fa-f
lower := choose(8, HEXLOWER)    # 0-9a-f
upper := choose(8, HEXUPPER)    # 0-9A-F
```

## Terminal Colors

```just
# Colors
red_text := RED + "Error!" + NORMAL
green_text := GREEN + "Success!" + NORMAL

# Styles
bold_text := BOLD + "Important" + NORMAL
underlined := UNDERLINE + "Link" + NORMAL

# Background
highlight := BG_YELLOW + BLACK + "Warning" + NORMAL
```

Available: `BLACK`, `RED`, `GREEN`, `YELLOW`, `BLUE`, `MAGENTA`, `CYAN`, `WHITE`
Background: `BG_BLACK`, `BG_RED`, etc.
Styles: `BOLD`, `ITALIC`, `UNDERLINE`, `INVERT`, `HIDE`, `STRIKETHROUGH`
Reset: `NORMAL`, `CLEAR`
