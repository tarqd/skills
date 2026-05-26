# TCC Diagnostic Commands

Copy-paste-ready commands for diagnosing TCC permission issues on macOS.

## Stream tccd Logs

### Watch all TCC activity for a specific app

```bash
/usr/bin/log stream --predicate 'subsystem == "com.apple.TCC"' --timeout 30 2>&1 \
  | grep -i '<bundle-id>'
```

### Watch all TCC activity (verbose)

```bash
/usr/bin/log stream --predicate 'subsystem == "com.apple.TCC"' --level debug
```

### Search recent logs (last N minutes)

```bash
/usr/bin/log show --predicate 'subsystem == "com.apple.TCC"' --last 5m 2>&1 \
  | grep -i '<bundle-id>'
```

### Key log patterns to look for

| Pattern | Meaning |
|---|---|
| `AUTHREQ_ATTRIBUTION` | tccd received the request; shows requesting process |
| `AUTHREQ_SUBJECT` | The identity being evaluated |
| `requires entitlement <key> but it is missing` | **Wrong or missing entitlement** |
| `Prompting policy … Deny` | Prompt suppressed (see reason) |
| `AUTHREQ_RESULT: authValue=0` | Access denied |
| `AUTHREQ_RESULT: authValue=1` | Access allowed |
| No entry at all | Framework never called tccd (check `requestAccess` call) |

## Verify Entitlements on Signed Binary

### Show all entitlements

```bash
codesign -d --entitlements - /path/to/App.app 2>&1
```

### Check for a specific entitlement

```bash
codesign -d --entitlements - /path/to/App.app 2>&1 | grep addressbook
```

### Verify signature and hardened runtime

```bash
codesign -v --verbose /path/to/App.app 2>&1
codesign -d --flags /path/to/App.app 2>&1    # should include "runtime"
```

### Show signing identity

```bash
codesign -d --verbose=2 /path/to/App.app 2>&1 | grep -E 'Authority|TeamIdentifier|Identifier'
```

## Query TCC Database

### All entries for a bundle ID

```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client, auth_value, auth_reason FROM access
   WHERE client LIKE '%<bundle-id>%';"
```

### All entries for a TCC service

```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client, auth_value, auth_reason FROM access
   WHERE service = 'kTCCServiceAddressBook';"
```

### auth_value meanings

| Value | Meaning |
|---|---|
| 0 | Denied |
| 2 | Allowed |
| 3 | Limited (iOS Contacts only) |

### auth_reason meanings

| Value | Meaning |
|---|---|
| 0 | Unknown |
| 1 | Error |
| 2 | User consent |
| 3 | User set |
| 4 | System set |
| 5 | Service policy |
| 6 | MDM policy |
| 12 | Extension disallowed |

## Reset TCC Grants

### Reset a specific service for an app

```bash
tccutil reset AddressBook <bundle-id>
tccutil reset Calendar <bundle-id>
tccutil reset Reminders <bundle-id>
tccutil reset Camera <bundle-id>
tccutil reset Microphone <bundle-id>
tccutil reset Photos <bundle-id>
```

### Reset ALL services for an app

```bash
tccutil reset All <bundle-id>
```

### Common mistakes

- `tccutil reset Contacts <id>` does NOT work — use `AddressBook`
- The bundle ID must match exactly (case-sensitive)
- "Successfully reset" output does not mean there was a row to reset

## Launch App for TCC Testing

### Launch as its own responsible process

```bash
open /path/to/App.app
```

This makes the app its own responsible process for TCC. If launched as a
child of a terminal, the terminal is the responsible process.

### Launch and watch TCC simultaneously

```bash
/usr/bin/log stream --predicate 'subsystem == "com.apple.TCC"' --timeout 30 2>&1 \
  | grep -i '<bundle-id>' &
sleep 1
open /path/to/App.app
wait
```

## Info.plist Verification

### Check that usage description keys are present

```bash
/usr/libexec/PlistBuddy -c "Print :NSContactsUsageDescription" /path/to/Info.plist
/usr/libexec/PlistBuddy -c "Print :NSCalendarsFullAccessUsageDescription" /path/to/Info.plist
/usr/libexec/PlistBuddy -c "Print :NSRemindersFullAccessUsageDescription" /path/to/Info.plist
```

### Dump all NS*UsageDescription keys

```bash
plutil -p /path/to/Info.plist | grep -i usage
```

Note: Missing `NS*UsageDescription` causes a crash on access attempt, not a
silent denial. This is different from missing entitlements (which cause silent
denial).
