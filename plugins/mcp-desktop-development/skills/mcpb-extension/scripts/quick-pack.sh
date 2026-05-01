#!/usr/bin/env bash
# Pack + self-signed sign + verify, in one step. For local dev only.
# Usage: quick-pack.sh [source-dir] [output.mcpb]
#   source-dir defaults to "."
#   output     defaults to "<basename(source-dir)>.mcpb"

set -euo pipefail

src="${1:-.}"
default_out="$(basename "$(cd "$src" && pwd)").mcpb"
out="${2:-$default_out}"

if ! command -v mcpb >/dev/null 2>&1; then
  echo "error: mcpb CLI not found on PATH." >&2
  echo "Install with: npm install -g @anthropic-ai/mcpb" >&2
  exit 127
fi

echo "==> packing $src → $out"
mcpb pack "$src" "$out"

echo "==> signing $out (self-signed)"
mcpb sign "$out" --self-signed

echo "==> verifying $out"
mcpb verify "$out"

echo
echo "done: $out"
mcpb info "$out"
