---
name: Installing Lychee
description: This skill provides installation instructions for lychee, a fast link checker. Use when someone asks to install lychee, set up lychee, get a link checker working, or needs help installing lychee on macOS, Linux, or via cargo/Docker.
version: 0.1.0
---

# Installing Lychee

## Overview

Lychee is a fast, asynchronous link checker written in Rust. To install lychee, use cargo, system package managers, or pre-built binaries depending on platform and preferences.

## Installation Methods


### Package Managers

Prefer package managers over building from source for simpler installation.

#### macOS (Homebrew)

```bash
brew install lychee
```

#### Linux (APT)

```bash
# Debian/Ubuntu
sudo apt install lychee
```

**Note:** Package manager versions may lag behind the latest release.

#### Arch Linux

```bash
pacman -S lychee
```

#### Nix

```bash
nix-env -iA nixpkgs.lychee
```

### Cargo

Requires Rust toolchain (install from https://rustup.rs):

```bash
cargo install lychee
# Or if binstall is available
cargo binstall lychee
```

Use cargo to always get the latest version, work across all platforms, and avoid dependency on system package managers.

### Pre-built Binaries

Download from GitHub releases for systems without package managers:

1. Visit https://github.com/lycheeverse/lychee/releases
2. Download appropriate binary for the platform
3. Extract and move to a directory in PATH:

```bash
# Example for Linux x86_64
wget https://github.com/lycheeverse/lychee/releases/latest/download/lychee-x86_64-unknown-linux-gnu.tar.gz
tar -xzf lychee-x86_64-unknown-linux-gnu.tar.gz
sudo mv lychee /usr/local/bin/
```

### Docker

To run lychee without installing locally, use Docker:

```bash
docker run --rm -it -v $(pwd):/workspace lycheeverse/lychee /workspace
```

Useful for CI/CD environments and one-off checks.

## Verification

After installation, verify lychee is available:

```bash
lychee --version
```

Expected output: `lychee X.Y.Z` with version number.

## Version Management

### Checking Current Version

```bash
lychee --version
```

### Upgrading

**Cargo:**
```bash
cargo install lychee --force
```

**Homebrew:**
```bash
brew upgrade lychee
```

**Package managers:**
```bash
# APT
sudo apt update && sudo apt upgrade lychee

# Pacman
sudo pacman -Syu lychee
```

## Troubleshooting

### Cargo Install Fails

**Issue:** Build errors during `cargo install`

**Solutions:**
1. Update Rust toolchain: `rustup update`
2. Check system has build dependencies (gcc, make)
3. Try pre-built binary instead

### Command Not Found

**Issue:** `lychee: command not found` after installation

**Solutions:**
1. Check PATH includes installation directory
2. For cargo: ensure `~/.cargo/bin` is in PATH
3. Restart terminal to refresh PATH
4. Verify installation: `which lychee`

### Permission Denied

**Issue:** Cannot move binary to /usr/local/bin

**Solution:** Use sudo or install to user directory:
```bash
mkdir -p ~/bin
mv lychee ~/bin/
# Add ~/bin to PATH if not already there
```

## Integration with GitHub Actions

For CI/CD workflows, use the lychee-action instead of installing manually:

```yaml
- name: Link Checker
  uses: lycheeverse/lychee-action@v2
  with:
    args: --verbose --no-progress '**/*.md'
```

See the `lychee-github-workflows` skill for complete workflow examples.

## Additional Resources

- **Official repository:** https://github.com/lycheeverse/lychee
- **Documentation:** https://lychee.cli.rs
- **Release notes:** https://github.com/lycheeverse/lychee/releases

## Next Steps

After installation:
1. Verify installation with `lychee --version`
2. Create a `lychee.toml` configuration file (see `configuring-lychee` skill)
3. Run first link check: `lychee README.md`
4. Set up caching with `--cache` flag for faster subsequent checks
