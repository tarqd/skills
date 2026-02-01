# Built-in Functions Reference

## System Information

```just
# CPU architecture (x86_64, aarch64, etc.)
arch := arch()

# Operating system (linux, macos, windows, etc.)
system := os()

# OS family (unix, windows)
family := os_family()

# Number of CPUs
cpus := num_cpus()
```

## Environment Variables

```just
# Get env var (error if missing)
home := env('HOME')

# Get with default
editor := env('EDITOR', 'vim')

# Deprecated alternatives
home := env_var('HOME')
editor := env_var_or_default('EDITOR', 'vim')
```

## Executables

```just
# Find executable or error
cargo := require('cargo')

# Find executable or empty string
npm := which('npm')

# Path to just binary
just_bin := just_executable()

# Just process ID
pid := just_pid()
```

## Paths & Directories

```just
# Where just was invoked
invoke_dir := invocation_directory()
invoke_dir := invocation_dir()

# Current justfile location
this_file := justfile()
this_dir := justfile_directory()

# Source file (in imports/modules)
src := source_file()
src_dir := source_directory()

# User directories
home := home_directory()
config := config_directory()
data := data_directory()
cache := cache_directory()
```

## Path Manipulation

### Fallible (can error)

```just
# Make path absolute
abs := absolute_path('relative/path')

# Resolve symlinks
real := canonicalize('link')

# Get extension (error if none)
ext := extension('file.txt')  # "txt"

# Get filename
name := file_name('/path/to/file.txt')  # "file.txt"

# Filename without extension
stem := file_stem('file.txt')  # "file"

# Parent directory
parent := parent_directory('/path/to/file')

# Remove extension
base := without_extension('file.txt')  # "file"
```

### Infallible

```just
# Simplify path (remove . and ..)
cleaned := clean('foo/./bar/../baz')  # "foo/baz"

# Join paths
full := join('base', 'sub', 'file.txt')
```

## String Functions

### Case Conversion

```just
kebab := kebabcase('HelloWorld')       # "hello-world"
snake := snakecase('HelloWorld')       # "hello_world"
upper_camel := uppercamelcase('hello') # "Hello"
lower_camel := lowercamelcase('Hello') # "hello"
shouty := shoutysnakecase('hello')     # "HELLO"
shouty_kebab := shoutykebabcase('hi')  # "HI"
title := titlecase('hello world')      # "Hello World"
lower := lowercase('HELLO')            # "hello"
upper := uppercase('hello')            # "HELLO"
cap := capitalize('hello')             # "Hello"
```

### Trimming

```just
trimmed := trim('  hello  ')           # "hello"
left := trim_start('  hello')          # "hello"
right := trim_end('hello  ')           # "hello"

# Remove specific prefix/suffix (once)
no_v := trim_start_match('v1.0', 'v')  # "1.0"
no_ext := trim_end_match('f.txt', '.txt')  # "f"

# Remove prefix/suffix (all occurrences)
clean := trim_start_matches('...hi', '.')  # "hi"
```

### Manipulation

```just
# Append/Prepend to each word
items := append('.rs', 'foo bar')      # "foo.rs bar.rs"
items := prepend('test_', 'a b')       # "test_a test_b"

# Replace
new := replace('hello', 'l', 'L')      # "heLLo"
new := replace_regex('a1b2', '\d', 'X')  # "aXbX"

# Shell escape
safe := quote("it's")                  # "'it'\\''s'"

# URL encode
encoded := encode_uri_component('a b') # "a%20b"
```

## Hash Functions

```just
# SHA-256
hash := sha256('hello')
file_hash := sha256_file('data.bin')

# BLAKE3 (faster)
hash := blake3('hello')
file_hash := blake3_file('data.bin')
```

## UUID

```just
id := uuid()  # Random UUID v4
```

## Random

```just
# 8 random hex characters
token := choose(8, HEX)

# Custom alphabet
code := choose(6, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
```

## Date/Time

```just
# Local time
now := datetime('%Y-%m-%d %H:%M:%S')
date := datetime('%Y-%m-%d')
time := datetime('%H:%M')

# UTC time
utc := datetime_utc('%Y-%m-%dT%H:%M:%SZ')
```

Format uses strftime syntax.

## Filesystem

```just
# Check if path exists
exists := path_exists('config.toml')

# Read file contents
content := read('VERSION')
```

## Shell Execution

```just
# Run shell command
result := shell('echo hello')
output := shell('date', '+%Y')
```

## Semver

```just
# Check version compatibility
ok := semver_matches('1.2.3', '>=1.0.0')
```

## Error

```just
# Halt with error message
check := if missing { error('Required file missing!') } else { 'ok' }
```

## Recipe Context

```just
# Check if running as dependency
is_dep := is_dependency()
```

## Terminal Styles

```just
# Get escape sequence for style
red := style('red')
bold := style('bold')

# Use in output
message := style('red') + "Error" + style('normal')
```

## Constants Reference

| Constant | Description |
|----------|-------------|
| `HEX` | `0-9A-Fa-f` |
| `HEXLOWER` | `0-9a-f` |
| `HEXUPPER` | `0-9A-F` |
| `PATH_SEP` | `/` or `\` |
| `PATH_VAR_SEP` | `:` or `;` |
