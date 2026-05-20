#!/usr/bin/env bash
# PostToolUse hook: advisory consistency check on ADR file edits.
# Emits a non-blocking systemMessage when something looks off.
# Silent on all non-ADR edits.

set -u

# jq is required to parse the tool-call JSON; bail silently if absent.
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

# Only Edit / Write / MultiEdit.
case "$tool_name" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

# Only paths under an ADR directory.
case "$file_path" in
  */docs/adr/*.md|*/docs/architecture/decisions/*.md|*/doc/adr/*.md|*/adr/*.md) ;;
  *) exit 0 ;;
esac

# Skip non-ADR files inside the ADR directory.
case "$(basename "$file_path")" in
  README.md|TEMPLATE.md|template.md|index.md) exit 0 ;;
esac

# After a successful Edit/Write the file should exist.
[ -f "$file_path" ] || exit 0

warnings=()

first_h1=$(grep -m1 '^# ' "$file_path" || true)
if [ -z "$first_h1" ]; then
  warnings+=("Missing H1 header.")
elif ! printf '%s\n' "$first_h1" | grep -Eq '^# (ADR[- ]|[0-9])'; then
  warnings+=("H1 doesn't look like an ADR header: '$first_h1'")
fi

if ! grep -Eq '^\*\*Status:?\*\*' "$file_path"; then
  warnings+=("No '**Status:**' line found.")
fi

file_num=$(basename "$file_path" .md | grep -Eo '[0-9]+' | head -1 || true)
header_num=$(printf '%s\n' "$first_h1" | grep -Eo '[0-9]+' | head -1 || true)
if [ -n "$file_num" ] && [ -n "$header_num" ]; then
  if [ "$((10#$file_num))" -ne "$((10#$header_num))" ]; then
    warnings+=("Filename number ($file_num) doesn't match H1 number ($header_num).")
  fi
fi

status_line=$(grep -E '^\*\*Status:?\*\*' "$file_path" | head -1 || true)
if printf '%s\n' "$status_line" | grep -Eiq 'Accepted|Deprecated|Superseded'; then
  status_value=$(printf '%s\n' "$status_line" | sed -E 's/^\*\*Status:?\*\*[[:space:]]*//; s/\.$//' | head -1)
  warnings+=("ADR status is '$status_value'. If this edit changes the decision (not just a typo or clarification), use \`adr supersede\` instead of editing in place.")
fi

if grep -Eiq '^Superseded by' "$file_path"; then
  warnings+=("This ADR is superseded — edits land in a historical document.")
fi

if [ ${#warnings[@]} -eq 0 ]; then
  exit 0
fi

msg="ADR edit check on $(basename "$file_path"):"
for w in "${warnings[@]}"; do
  msg="$msg
  • $w"
done

jq -nc --arg msg "$msg" '{continue: true, systemMessage: $msg}'
exit 0
