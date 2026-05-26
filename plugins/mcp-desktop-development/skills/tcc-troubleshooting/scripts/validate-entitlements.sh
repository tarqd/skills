#!/usr/bin/env bash
#
# validate-entitlements.sh — check an entitlements plist (and optionally a
# signed .app) against the known TCC service→entitlement mapping.
#
# Usage:
#   validate-entitlements.sh /path/to/entitlements.plist [/path/to/App.app]
#
# Flags wrong keys, missing keys, and mismatches between the source plist
# and the signed binary.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ENTITLEMENTS_PLIST="${1:?Usage: validate-entitlements.sh <entitlements.plist> [App.app]}"
APP_BUNDLE="${2:-}"

# Known TCC entitlement keys and their correct forms.
# Format: "wrong_suffix:correct_key:tcc_service:friendly_name"
declare -a KNOWN_MAPPINGS=(
  "contacts:com.apple.security.personal-information.addressbook:kTCCServiceAddressBook:Contacts"
  "addressbook:com.apple.security.personal-information.addressbook:kTCCServiceAddressBook:Contacts"
  "calendars:com.apple.security.personal-information.calendars:kTCCServiceCalendar:Calendar"
  "reminders:com.apple.security.personal-information.reminders:kTCCServiceReminders:Reminders"
  "photos-library:com.apple.security.personal-information.photos-library:kTCCServicePhotos:Photos"
  "photos:com.apple.security.personal-information.photos-library:kTCCServicePhotos:Photos"
  "media-library:com.apple.security.personal-information.media-library:kTCCServiceMediaLibrary:Media"
  "location:com.apple.security.personal-information.location:kTCCServiceLocation:Location"
  "camera:com.apple.security.device.camera:kTCCServiceCamera:Camera"
  "microphone:com.apple.security.device.microphone:kTCCServiceMicrophone:Microphone"
  "bluetooth:com.apple.security.device.bluetooth:kTCCServiceBluetoothAlways:Bluetooth"
  "usb:com.apple.security.device.usb:kTCCServiceUSBDevice:USB"
)

# Common wrong-key → correct-key mappings (pipe-delimited to avoid bash
# associative-array issues with dots in keys).
WRONG_KEY_PAIRS="
com.apple.security.personal-information.contacts|com.apple.security.personal-information.addressbook
com.apple.security.personal-information.photos|com.apple.security.personal-information.photos-library
"

errors=0
warnings=0

echo "=== TCC Entitlement Validator ==="
echo ""

# --- Check source entitlements plist ---
echo "Checking: $ENTITLEMENTS_PLIST"

if [[ ! -f "$ENTITLEMENTS_PLIST" ]]; then
  echo -e "${RED}ERROR: File not found: $ENTITLEMENTS_PLIST${NC}"
  exit 1
fi

# Extract all keys from the plist
keys=$(plutil -p "$ENTITLEMENTS_PLIST" | grep -oE '"[^"]+"' | tr -d '"' || true)

for key in $keys; do
  # Check against known wrong keys
  while IFS='|' read -r wrong correct; do
    [[ -z "$wrong" ]] && continue
    if [[ "$key" == "$wrong" ]]; then
      echo -e "${RED}ERROR: Wrong entitlement key${NC}"
      echo "  Found:    $key"
      echo "  Expected: $correct"
      echo "  TCC will silently deny access with this key."
      ((errors++))
    fi
  done <<< "$WRONG_KEY_PAIRS"
done

# Check that personal-information keys use correct suffixes
for key in $keys; do
  if [[ "$key" == com.apple.security.personal-information.* ]]; then
    suffix="${key#com.apple.security.personal-information.}"
    found_match=false
    for mapping in "${KNOWN_MAPPINGS[@]}"; do
      IFS=: read -r m_suffix m_key m_service m_name <<< "$mapping"
      if [[ "$key" == "$m_key" ]]; then
        echo -e "${GREEN}  OK: $key → $m_service ($m_name)${NC}"
        found_match=true
        break
      fi
    done
    if [[ "$found_match" == "false" ]]; then
      echo -e "${YELLOW}  WARN: Unrecognized entitlement: $key${NC}"
      ((warnings++))
    fi
  elif [[ "$key" == com.apple.security.device.* ]]; then
    suffix="${key#com.apple.security.device.}"
    found_match=false
    for mapping in "${KNOWN_MAPPINGS[@]}"; do
      IFS=: read -r m_suffix m_key m_service m_name <<< "$mapping"
      if [[ "$key" == "$m_key" ]]; then
        echo -e "${GREEN}  OK: $key → $m_service ($m_name)${NC}"
        found_match=true
        break
      fi
    done
    if [[ "$found_match" == "false" ]]; then
      echo -e "${YELLOW}  WARN: Unrecognized device entitlement: $key${NC}"
      ((warnings++))
    fi
  fi
done

# --- Check signed binary if provided ---
if [[ -n "$APP_BUNDLE" ]]; then
  echo ""
  echo "Checking signed binary: $APP_BUNDLE"

  if [[ ! -d "$APP_BUNDLE" ]]; then
    echo -e "${RED}ERROR: App bundle not found: $APP_BUNDLE${NC}"
    exit 1
  fi

  # Verify signature
  if ! codesign -v "$APP_BUNDLE" 2>/dev/null; then
    echo -e "${RED}ERROR: Invalid or missing signature on $APP_BUNDLE${NC}"
    ((errors++))
  else
    echo -e "${GREEN}  Signature: valid${NC}"
  fi

  # Check hardened runtime
  flags=$(codesign -d --flags "$APP_BUNDLE" 2>&1 || true)
  if echo "$flags" | grep -q "runtime"; then
    echo -e "${GREEN}  Hardened runtime: enabled${NC}"
  else
    echo -e "${YELLOW}  WARN: Hardened runtime not enabled — TCC may not prompt on macOS 15+${NC}"
    ((warnings++))
  fi

  # Extract entitlements from signed binary
  signed_ents=$(codesign -d --entitlements - "$APP_BUNDLE" 2>&1 || true)

  # Compare source vs signed for each key
  for key in $keys; do
    if [[ "$key" == com.apple.security.* ]]; then
      if echo "$signed_ents" | grep -q "$key"; then
        echo -e "${GREEN}  Signed binary has: $key${NC}"
      else
        echo -e "${RED}ERROR: Source has $key but signed binary does NOT${NC}"
        echo "  The signing step may not be applying the entitlements file."
        ((errors++))
      fi
    fi
  done
fi

# --- Summary ---
echo ""
if [[ $errors -gt 0 ]]; then
  echo -e "${RED}$errors error(s), $warnings warning(s)${NC}"
  exit 1
elif [[ $warnings -gt 0 ]]; then
  echo -e "${YELLOW}0 errors, $warnings warning(s)${NC}"
  exit 0
else
  echo -e "${GREEN}All entitlements valid.${NC}"
  exit 0
fi
