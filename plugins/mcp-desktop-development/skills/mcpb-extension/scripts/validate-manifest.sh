#!/usr/bin/env bash
# Validate an MCPB manifest with a clear, actionable failure message.
# Usage: validate-manifest.sh [path]   (default: ./manifest.json)

set -euo pipefail

target="${1:-manifest.json}"

if ! command -v mcpb >/dev/null 2>&1; then
  echo "error: mcpb CLI not found on PATH." >&2
  echo "Install with: npm install -g @anthropic-ai/mcpb" >&2
  exit 127
fi

if [[ ! -e "$target" ]]; then
  echo "error: $target does not exist." >&2
  exit 2
fi

if mcpb validate "$target"; then
  echo "ok: $target is a valid MCPB manifest."
else
  rc=$?
  echo "error: $target failed validation (mcpb exit $rc)." >&2
  echo "Hint: check 'manifest_version' matches the fields you're using." >&2
  echo "      0.3 = current default, 0.4 = adds 'uv' server type." >&2
  exit "$rc"
fi
