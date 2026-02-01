#!/usr/bin/env bash
#
# Check for duplicate plugin names in marketplace.json
#
# Usage: ./ci/check-duplicates.sh
#
# Exit codes:
#   0 - No duplicates found
#   1 - Duplicates found

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Find repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE_JSON="${REPO_ROOT}/.claude-plugin/marketplace.json"

echo "Checking for duplicate plugin names..."

duplicates=$(jq -r '.plugins[].name' "${MARKETPLACE_JSON}" | sort | uniq -d)

if [ -n "$duplicates" ]; then
    echo -e "${RED}✗${NC} Duplicate plugin names found:"
    echo "$duplicates"
    exit 1
fi

echo -e "${GREEN}✓${NC} No duplicate plugin names"
