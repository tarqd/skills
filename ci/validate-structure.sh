#!/usr/bin/env bash
#
# Validate plugin directory structure and required files
#
# Usage: ./ci/validate-structure.sh
#
# Exit codes:
#   0 - All plugins valid
#   1 - Validation errors found

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Find repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE_JSON="${REPO_ROOT}/.claude-plugin/marketplace.json"

echo "Validating plugin structure..."

# Get all plugin paths (local string sources only)
plugins=$(jq -r '.plugins[] | select(.source | type == "string") | .source' "${MARKETPLACE_JSON}")

for plugin_path in $plugins; do
    full_path="${REPO_ROOT}/${plugin_path}"
    plugin_name=$(basename "$plugin_path")
    echo ""
    echo "Checking plugin: $plugin_name"
    echo "================================"

    # Check directory exists
    if [ ! -d "$full_path" ]; then
        echo -e "${RED}✗${NC} Directory not found: $plugin_path"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Directory exists"

    # Check plugin.json exists
    plugin_json="$full_path/.claude-plugin/plugin.json"
    if [ ! -f "$plugin_json" ]; then
        echo -e "${RED}✗${NC} plugin.json not found at $plugin_path/.claude-plugin/plugin.json"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} plugin.json exists"

    # Check README exists
    if [ ! -f "$full_path/README.md" ]; then
        echo -e "${YELLOW}⚠️  Warning:${NC} README.md not found (recommended)"
    else
        echo -e "${GREEN}✓${NC} README.md exists"
    fi

    # Check commands directory and validate command files
    if [ -d "$full_path/commands" ]; then
        echo -e "${GREEN}✓${NC} Commands directory exists"

        # Find all markdown files in commands directory
        while IFS= read -r -d '' cmd_file; do
            cmd_name=$(basename "$cmd_file")

            # Check if file has frontmatter (starts with ---)
            if head -n 1 "$cmd_file" | grep -q "^---$"; then
                echo -e "${GREEN}✓${NC} Command '$cmd_name' has frontmatter"
            else
                echo -e "${YELLOW}⚠️  Warning:${NC} Command '$cmd_name' missing frontmatter (recommended)"
            fi
        done < <(find "$full_path/commands" -name "*.md" -type f -print0 2>/dev/null)
    fi

    echo -e "${GREEN}✓${NC} Plugin $plugin_name is valid"
done

echo ""
echo "================================"
echo -e "${GREEN}✅ All plugins validated successfully!${NC}"
