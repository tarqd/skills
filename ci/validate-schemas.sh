#!/usr/bin/env bash
#
# Validate all marketplace.json and plugin.json files against their schemas
# using the sourcemeta/jsonschema CLI: https://github.com/sourcemeta/jsonschema
#
# Usage: ./ci/validate-schemas.sh
#
# Exit codes:
#   0 - All files valid
#   1 - Validation errors found
#   2 - Missing dependencies or schema files

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Find repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Schema paths
PLUGIN_SCHEMA="${REPO_ROOT}/schemas/plugin.schema.json"
MARKETPLACE_SCHEMA="${REPO_ROOT}/schemas/marketplace.schema.json"

# Counters
ERRORS=0
VALIDATED=0

# Check if jsonschema CLI is installed
if ! command -v jsonschema &> /dev/null; then
    echo -e "${RED}Error: jsonschema CLI not found${NC}"
    echo ""
    echo "Install it from: https://github.com/sourcemeta/jsonschema"
    echo ""
    echo "Installation options:"
    echo "  macOS:  brew install sourcemeta/apps/jsonschema"
    echo "  cargo:  cargo install jsonschema"
    echo "  npm:    npm install -g @sourcemeta/jsonschema"
    exit 2
fi

# Check schema files exist
if [[ ! -f "${PLUGIN_SCHEMA}" ]]; then
    echo -e "${RED}Error: Plugin schema not found at ${PLUGIN_SCHEMA}${NC}"
    exit 2
fi

if [[ ! -f "${MARKETPLACE_SCHEMA}" ]]; then
    echo -e "${RED}Error: Marketplace schema not found at ${MARKETPLACE_SCHEMA}${NC}"
    exit 2
fi

echo "Validating JSON files against schemas..."
echo ""

# Validate marketplace.json files
echo "=== Marketplace manifests ==="
while IFS= read -r -d '' file; do
    relative_path="${file#"${REPO_ROOT}/"}"
    if jsonschema validate "${MARKETPLACE_SCHEMA}" "${file}" 2>&1; then
        echo -e "${GREEN}✓${NC} ${relative_path}"
        ((VALIDATED++))
    else
        echo -e "${RED}✗${NC} ${relative_path}"
        ((ERRORS++))
    fi
done < <(find "${REPO_ROOT}" -name "marketplace.json" -type f -not -path "*/templates/*" -print0)

echo ""

# Validate plugin.json files (only those in .claude-plugin directories)
echo "=== Plugin manifests ==="
while IFS= read -r -d '' file; do
    relative_path="${file#"${REPO_ROOT}/"}"
    if jsonschema validate "${PLUGIN_SCHEMA}" "${file}" 2>&1; then
        echo -e "${GREEN}✓${NC} ${relative_path}"
        ((VALIDATED++))
    else
        echo -e "${RED}✗${NC} ${relative_path}"
        ((ERRORS++))
    fi
done < <(find "${REPO_ROOT}" -path "*/.claude-plugin/plugin.json" -type f -not -path "*/templates/*" -print0)

echo ""
echo "=== Summary ==="
echo -e "Validated: ${GREEN}${VALIDATED}${NC} files"

if [[ ${ERRORS} -gt 0 ]]; then
    echo -e "Errors: ${RED}${ERRORS}${NC} files"
    exit 1
else
    echo -e "${GREEN}All files valid!${NC}"
    exit 0
fi
