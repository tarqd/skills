---
name: tcc-troubleshooting
description: >-
  This skill should be used when the user asks to "debug TCC permissions",
  "fix TCC prompt not appearing", "validate entitlements", "troubleshoot
  privacy permissions", "check why my app can't access contacts/calendar/reminders",
  "TCC access denied", "entitlement mismatch", "tccutil reset", "tccd logs",
  or mentions TCC, Transparency Consent and Control, kTCCService, privacy
  prompts, or hardened runtime entitlement issues on macOS.
version: 0.1.0
---

# TCC Troubleshooting

Diagnose and fix macOS TCC (Transparency, Consent, and Control) permission
issues. TCC gates access to Contacts, Calendar, Reminders, Camera, Microphone,
Location, and other protected resources. When a TCC prompt fails to appear or
access is silently denied, the root cause is almost always one of three things:
wrong entitlement key, missing entitlement entirely, or a responsible-process
mismatch.

## Critical: Entitlement Key ≠ Framework Name

The single most common TCC failure is using the wrong entitlement key. TCC
service names and entitlement keys do **not** always match the framework name.
The canonical mapping is in `references/tcc-entitlement-mapping.md` — consult
it before adding or validating any entitlement.

**The gotcha that bites hardest:** Contacts framework access requires
`com.apple.security.personal-information.addressbook`, NOT
`com.apple.security.personal-information.contacts`. TCC will silently refuse
to prompt if the entitlement key is wrong.

## Diagnostic Workflow

When a TCC prompt does not appear or access is denied:

### 1. Stream tccd logs and reproduce

```bash
/usr/bin/log stream --predicate 'subsystem == "com.apple.TCC"' --timeout 30 2>&1 \
  | grep -i '<bundle-id-or-keyword>'
```

Then trigger the access attempt. Look for:
- `AUTHREQ_ATTRIBUTION` — confirms tccd received the request and shows the
  requesting process identity.
- `requires entitlement <key> but it is missing` — **wrong or missing
  entitlement**. Cross-reference `references/tcc-entitlement-mapping.md`.
- `Prompting policy … Deny because: is Platform Binary` — system binary,
  cannot be prompted.
- No log entry at all — the framework call never reached tccd. Check that
  `requestAccess` / `requestFullAccessTo*` is actually being called.

### 2. Verify entitlements on the signed binary

```bash
codesign -d --entitlements - /path/to/App.app 2>&1
```

Compare the output against the expected keys from
`references/tcc-entitlement-mapping.md`. The entitlements must be embedded
in the codesigned binary — having them only in the source `.entitlements`
file is not enough if the signing step doesn't apply them.

### 3. Check current TCC database state

```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client, auth_value, auth_reason FROM access
   WHERE client LIKE '%<bundle-id>%';"
```

`auth_value` meanings: 0 = denied, 2 = allowed, 3 = limited.
If there is no row, TCC has never been asked for this service+client pair.

### 4. Reset and retry

```bash
tccutil reset <ServiceName> <bundle-id>
```

Service names for tccutil: `AddressBook`, `Calendar`, `Reminders`,
`Camera`, `Microphone`, `Photos`, `ScreenCapture`, `Accessibility`,
`SystemPolicyAllFiles`. Note: `tccutil reset Contacts ...` does NOT work —
use `AddressBook`.

### 5. Validate the entitlements file

Run the validation script on the entitlements plist and the signed binary:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/tcc-troubleshooting/scripts/validate-entitlements.sh" \
  /path/to/entitlements.plist [/path/to/App.app]
```

The script cross-references every `com.apple.security.personal-information.*`
key against the known TCC mapping and flags mismatches.

## macOS 26+ Hardened Runtime Requirement

Starting with macOS 15 (Sequoia), hardened-runtime apps **must** carry the
correct `com.apple.security.personal-information.*` entitlement for TCC to
even show a prompt. Without it, `requestAccess` returns denied and tccd logs
the missing-entitlement error. This is a change from earlier macOS versions
where the entitlement was recommended but not strictly required for the prompt.

Verify hardened runtime is enabled:

```bash
codesign -d --flags /path/to/App.app 2>&1   # should show "runtime"
```

## Responsible Process

TCC attributes the permission prompt to the "responsible process" — the
top-level app that launched the requesting binary. When a CLI tool runs inside
a terminal (Ghostty, Terminal.app, iTerm), the terminal is the responsible
process and gets the TCC prompt. When a binary runs inside an `.app` bundle
launched via `open`, it is its own responsible process.

For MCPB extensions in Claude Desktop, the `.app` bundle wrapper gives the
binary its own TCC identity via `CFBundleIdentifier`.

## Apple Documentation

Apple developer docs are available as rendered pages. To fetch raw markdown
when the JavaScript-rendered page returns empty, append `.md` to the URL path:

```
https://developer.apple.com/documentation/contacts/accessing-the-contact-store.md
```

Key documentation pages for TCC-related entitlements:
- `bundleresources/entitlements/com_apple_security_personal-information_addressbook`
- `bundleresources/entitlements/com_apple_security_personal-information_calendars`
- `contacts/accessing-the-contact-store`
- `eventkit/accessing-the-event-store`

## Additional Resources

### Reference Files

- **`references/tcc-entitlement-mapping.md`** — Complete mapping of TCC
  services to entitlement keys, Info.plist usage-description keys, and
  tccutil service names. **Consult before adding any entitlement.**
- **`references/diagnostic-commands.md`** — Copy-paste-ready commands for
  tccd log streaming, codesign inspection, TCC database queries, and tccutil
  reset.

### Scripts

- **`scripts/validate-entitlements.sh`** — Validates an entitlements plist
  (and optionally a signed .app bundle) against the known TCC mapping. Flags
  wrong keys, missing keys, and mismatches between source and signed binary.
