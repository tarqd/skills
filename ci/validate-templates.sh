#!/usr/bin/env bash
# Validate all kickstart templates in the templates directory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

errors=0
validated=0

echo "Validating kickstart templates in $TEMPLATES_DIR"
echo

for template_toml in "$TEMPLATES_DIR"/*/template.toml; do
    if [[ -f "$template_toml" ]]; then
        template_name="$(basename "$(dirname "$template_toml")")"

        if kickstart validate "$template_toml" > /dev/null 2>&1; then
            echo "✓ $template_name"
            ((validated++))
        else
            echo "✗ $template_name"
            kickstart validate "$template_toml" 2>&1 | sed 's/^/  /'
            ((errors++))
        fi
    fi
done

echo
echo "Validated: $validated, Errors: $errors"

if [[ $errors -gt 0 ]]; then
    exit 1
fi
