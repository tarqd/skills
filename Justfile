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

# Add this marketplace locally to Claude Code
[group('setup')]
add-marketplace:
    claude plugin marketplace add {{justfile_directory()}}

# Update this marketplace in Claude Code
[group('setup')]
update:
    claude plugin marketplace update $(jq -r .name {{justfile_directory()}}/.claude-plugin/marketplace.json)

# Remove this marketplace from Claude Code
[group('setup')]
remove-marketplace:
    claude plugin marketplace remove $(jq -r .name {{justfile_directory()}}/.claude-plugin/marketplace.json)

# Install a plugin from this marketplace
[group('setup')]
install plugin="":
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    plugin="{{plugin}}"
    if [[ -z "$plugin" ]]; then
        echo "📂 Available plugins:"
        jq -r '.plugins[].name' "$manifest" | sed 's/^/   /'
        echo
        read -p "Plugin name: " plugin
    fi
    id="$plugin@$marketplace"
    installed=$(claude plugin list --json | jq -r --arg id "$id" '.[] | select(.id == $id) | .id')
    if [[ -n "$installed" ]]; then
        echo "✓ $id is already installed"
    else
        claude plugin install "$id"
    fi

# Uninstall a plugin from this marketplace
[group('setup')]
uninstall plugin="":
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    plugin="{{plugin}}"
    if [[ -z "$plugin" ]]; then
        echo "📂 Available plugins:"
        jq -r '.plugins[].name' "$manifest" | sed 's/^/   /'
        echo
        read -p "Plugin name: " plugin
    fi
    id="$plugin@$marketplace"
    installed=$(claude plugin list --json | jq -r --arg id "$id" '.[] | select(.id == $id) | .id')
    if [[ -z "$installed" ]]; then
        echo "✓ $id is not installed"
    else
        claude plugin uninstall "$id"
    fi

# Install all plugins from this marketplace
[group('setup')]
install-all:
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    installed=$(claude plugin list --json)
    for plugin in $(jq -r '.plugins[].name' "$manifest"); do
        id="$plugin@$marketplace"
        exists=$(echo "$installed" | jq -r --arg id "$id" '.[] | select(.id == $id) | .id')
        if [[ -n "$exists" ]]; then
            echo "✓ $id is already installed"
        else
            echo "Installing $id..."
            claude plugin install "$id"
        fi
    done

# Uninstall all plugins from this marketplace
[group('setup')]
uninstall-all:
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    installed=$(claude plugin list --json)
    for plugin in $(jq -r '.plugins[].name' "$manifest"); do
        id="$plugin@$marketplace"
        exists=$(echo "$installed" | jq -r --arg id "$id" '.[] | select(.id == $id) | .id')
        if [[ -z "$exists" ]]; then
            echo "✓ $id is not installed"
        else
            echo "Uninstalling $id..."
            claude plugin uninstall "$id"
        fi
    done

# Enable a plugin from this marketplace
[group('setup')]
enable plugin="":
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    plugin="{{plugin}}"
    if [[ -z "$plugin" ]]; then
        echo "📂 Available plugins:"
        jq -r '.plugins[].name' "$manifest" | sed 's/^/   /'
        echo
        read -p "Plugin name: " plugin
    fi
    id="$plugin@$marketplace"
    enabled=$(claude plugin list --json | jq -r --arg id "$id" '.[] | select(.id == $id) | .enabled')
    if [[ "$enabled" == "true" ]]; then
        echo "✓ $id is already enabled"
    elif [[ -z "$enabled" ]]; then
        echo "Installing $id..."
        claude plugin install "$id"
    else
        claude plugin enable "$id"
    fi

# Disable a plugin from this marketplace
[group('setup')]
disable plugin="":
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    plugin="{{plugin}}"
    if [[ -z "$plugin" ]]; then
        echo "📂 Available plugins:"
        jq -r '.plugins[].name' "$manifest" | sed 's/^/   /'
        echo
        read -p "Plugin name: " plugin
    fi
    id="$plugin@$marketplace"
    enabled=$(claude plugin list --json | jq -r --arg id "$id" '.[] | select(.id == $id) | .enabled')
    if [[ "$enabled" == "false" ]]; then
        echo "✓ $id is already disabled"
    elif [[ -z "$enabled" ]]; then
        echo "✓ $id is not installed"
    else
        claude plugin disable "$id"
    fi

# Enable all plugins from this marketplace
[group('setup')]
enable-all:
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    installed=$(claude plugin list --json)
    for plugin in $(jq -r '.plugins[].name' "$manifest"); do
        id="$plugin@$marketplace"
        enabled=$(echo "$installed" | jq -r --arg id "$id" '.[] | select(.id == $id) | .enabled')
        if [[ "$enabled" == "true" ]]; then
            echo "✓ $id is already enabled"
        elif [[ -z "$enabled" ]]; then
            echo "Installing $id..."
            claude plugin install "$id"
        else
            echo "Enabling $id..."
            claude plugin enable "$id"
        fi
    done

# Disable all plugins from this marketplace
[group('setup')]
disable-all:
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{justfile_directory()}}/.claude-plugin/marketplace.json"
    marketplace=$(jq -r .name "$manifest")
    installed=$(claude plugin list --json)
    for plugin in $(jq -r '.plugins[].name' "$manifest"); do
        id="$plugin@$marketplace"
        enabled=$(echo "$installed" | jq -r --arg id "$id" '.[] | select(.id == $id) | .enabled')
        if [[ "$enabled" == "false" ]]; then
            echo "✓ $id is already disabled"
        elif [[ -z "$enabled" ]]; then
            echo "✓ $id is not installed"
        else
            echo "Disabling $id..."
            claude plugin disable "$id"
        fi
    done

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
