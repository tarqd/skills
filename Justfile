set quiet

# Show available commands
[default]
help:
    @just --list --unsorted --justfile {{justfile()}}

# ─────────────────────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────────────────────

# Install all dependencies via Homebrew
[group('setup')]
[macos]
setup:
    brew install kickstart jq sourcemeta/apps/jsonschema

# ─────────────────────────────────────────────────────────────────────────────
# Create & Scaffold
# ─────────────────────────────────────────────────────────────────────────────

# Create a new plugin and register it in the marketplace
[group('create')]
new-plugin:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Creating new plugin..."
    echo
    kickstart {{justfile_directory()}}/templates/claude-plugin -o {{justfile_directory()}}/plugins
    # Find the newly created plugin directory
    created_dir=$(ls -td {{justfile_directory()}}/plugins/*/ 2>/dev/null | head -1)
    if [[ -z "$created_dir" ]]; then
        echo "❌ No plugin directory created"
        exit 1
    fi
    plugin_name=$(basename "$created_dir")
    # Add to marketplace.json if not already present
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    if ! jq -e ".plugins[] | select(.name == \"$plugin_name\")" "$manifest" > /dev/null 2>&1; then
        jq ".plugins += [{\"name\": \"$plugin_name\", \"source\": \"./plugins/$plugin_name\", \"category\": \"utilities\", \"tags\": [], \"keywords\": []}]" \
            "$manifest" > "$manifest.tmp"
        mv "$manifest.tmp" "$manifest"
        echo
        echo "✅ Created plugin '$plugin_name' and added to marketplace"
    else
        echo
        echo "⚠️  Plugin '$plugin_name' already exists in marketplace.json"
    fi

# Add a skill to a plugin
[group('create')]
add-skill plugin="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{justfile_directory()}}
    plugin="{{plugin}}"
    if [[ -z "$plugin" ]]; then
        echo "📂 Available plugins:"
        ls -1 plugins/ | sed 's/^/   /'
        echo
        read -p "Plugin name: " plugin
    fi
    if [[ ! -d "plugins/$plugin" ]]; then
        echo "❌ Plugin '$plugin' not found in plugins/" >&2
        exit 1
    fi
    echo
    echo "🎯 Adding skill to '$plugin'..."
    echo
    mkdir -p "plugins/$plugin/skills"
    kickstart templates/claude-skill -o "plugins/$plugin/skills"
    echo
    echo "✅ Skill added to plugins/$plugin/skills/"

# Add an agent to a plugin
[group('create')]
add-agent plugin="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{justfile_directory()}}
    plugin="{{plugin}}"
    if [[ -z "$plugin" ]]; then
        echo "📂 Available plugins:"
        ls -1 plugins/ | sed 's/^/   /'
        echo
        read -p "Plugin name: " plugin
    fi
    if [[ ! -d "plugins/$plugin" ]]; then
        echo "❌ Plugin '$plugin' not found in plugins/" >&2
        exit 1
    fi
    echo
    echo "🤖 Adding agent to '$plugin'..."
    echo
    mkdir -p "plugins/$plugin/agents"
    kickstart templates/claude-agent -o "plugins/$plugin/agents"
    echo
    echo "✅ Agent added to plugins/$plugin/agents/"

# Add a hook to a plugin
[group('create')]
add-hook plugin="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{justfile_directory()}}
    plugin="{{plugin}}"
    if [[ -z "$plugin" ]]; then
        echo "📂 Available plugins:"
        ls -1 plugins/ | sed 's/^/   /'
        echo
        read -p "Plugin name: " plugin
    fi
    if [[ ! -d "plugins/$plugin" ]]; then
        echo "❌ Plugin '$plugin' not found in plugins/" >&2
        exit 1
    fi
    echo
    echo "🪝 Adding hook to '$plugin'..."
    echo
    mkdir -p "plugins/$plugin/hooks"
    kickstart templates/claude-hook -o "plugins/$plugin/hooks"
    echo
    echo "✅ Hook added to plugins/$plugin/hooks/"

# ─────────────────────────────────────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────────────────────────────────────

# Validate plugin.json and marketplace.json against schemas
[group('validate')]
validate-schemas:
    {{justfile_directory()}}/ci/validate-schemas.sh

# Validate plugin structure and check for duplicates
[group('validate')]
validate-marketplace: validate-schemas
    {{justfile_directory()}}/ci/validate-structure.sh
    {{justfile_directory()}}/ci/check-duplicates.sh

# Validate kickstart templates
[group('validate')]
validate-templates:
    {{justfile_directory()}}/ci/validate-templates.sh

# Run all validations
[group('validate')]
validate: validate-marketplace validate-templates

# ─────────────────────────────────────────────────────────────────────────────
# CI
# ─────────────────────────────────────────────────────────────────────────────

# CI entrypoint - runs all validations
[group('ci')]
ci: validate
