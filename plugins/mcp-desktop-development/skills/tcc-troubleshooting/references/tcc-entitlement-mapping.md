# TCC Service → Entitlement Key Mapping

This is the authoritative mapping between macOS TCC service identifiers,
the hardened-runtime entitlement keys they require, the Info.plist usage
description keys, and the `tccutil` service names used for resetting grants.

**The entitlement key is what TCC checks at prompt time.** If the key is
wrong, TCC silently denies access — no prompt, no error in the app, only a
log line in tccd.

## Personal Information Services

| TCC Service | Entitlement Key | Info.plist Usage Key | tccutil Name |
|---|---|---|---|
| `kTCCServiceAddressBook` | `com.apple.security.personal-information.addressbook` | `NSContactsUsageDescription` | `AddressBook` |
| `kTCCServiceCalendar` | `com.apple.security.personal-information.calendars` | `NSCalendarsFullAccessUsageDescription` (macOS 14+) / `NSCalendarsUsageDescription` (earlier) | `Calendar` |
| `kTCCServiceReminders` | `com.apple.security.personal-information.reminders` | `NSRemindersFullAccessUsageDescription` (macOS 14+) / `NSRemindersUsageDescription` (earlier) | `Reminders` |
| `kTCCServicePhotos` | `com.apple.security.personal-information.photos-library` | `NSPhotoLibraryUsageDescription` | `Photos` |
| `kTCCServiceMediaLibrary` | `com.apple.security.personal-information.media-library` | `NSAppleMusicUsageDescription` | `MediaLibrary` |
| `kTCCServiceLocation` | `com.apple.security.personal-information.location` | `NSLocationUsageDescription` / `NSLocationWhenInUseUsageDescription` | `Location` |

### Common Mistakes

- **Contacts**: The framework is `Contacts.framework` (`CNContactStore`), but
  the entitlement key uses `addressbook`, not `contacts`. This is a legacy
  naming artifact from the AddressBook.framework era.
- **Photos**: The entitlement uses `photos-library`, not `photos`.
- **Calendar vs Reminders**: Both use EventKit but have separate TCC services
  and entitlement keys.

## Hardware Services

| TCC Service | Entitlement Key | Info.plist Usage Key | tccutil Name |
|---|---|---|---|
| `kTCCServiceCamera` | `com.apple.security.device.camera` | `NSCameraUsageDescription` | `Camera` |
| `kTCCServiceMicrophone` | `com.apple.security.device.microphone` | `NSMicrophoneUsageDescription` | `Microphone` |
| `kTCCServiceBluetoothAlways` | `com.apple.security.device.bluetooth` | `NSBluetoothAlwaysUsageDescription` | `BluetoothAlways` |
| `kTCCServiceUSBDevice` | `com.apple.security.device.usb` | `NSUSBUsageDescription` | `USBDevice` |

## System Services

| TCC Service | Entitlement Key | Info.plist Usage Key | tccutil Name |
|---|---|---|---|
| `kTCCServiceSystemPolicyAllFiles` | `com.apple.security.files.all` | `NSSystemAdminUsageDescription` | `SystemPolicyAllFiles` |
| `kTCCServiceSystemPolicyDesktopFolder` | `com.apple.security.files.desktop-folder.read-write` | `NSDesktopFolderUsageDescription` | `SystemPolicyDesktopFolder` |
| `kTCCServiceSystemPolicyDocumentsFolder` | `com.apple.security.files.documents-folder.read-write` | `NSDocumentsFolderUsageDescription` | `SystemPolicyDocumentsFolder` |
| `kTCCServiceSystemPolicyDownloadsFolder` | `com.apple.security.files.downloads-folder.read-write` | `NSDownloadsFolderUsageDescription` | `SystemPolicyDownloadsFolder` |
| `kTCCServiceAccessibility` | *(no entitlement — requires System Settings toggle)* | — | `Accessibility` |
| `kTCCServiceScreenCapture` | *(no entitlement — requires System Settings toggle)* | — | `ScreenCapture` |
| `kTCCServiceSpeechRecognition` | `com.apple.security.device.audio-input` | `NSSpeechRecognitionUsageDescription` | `SpeechRecognition` |

## Notes

- **Accessibility and ScreenCapture** cannot be granted via entitlements or
  `requestAccess`. They require manual toggle in System Settings → Privacy &
  Security.
- **Sandboxed apps** use `com.apple.security.app-sandbox` plus specific
  `com.apple.security.temporary-exception.*` keys. Non-sandboxed
  hardened-runtime apps use the keys listed above.
- **macOS 15+**: Hardened-runtime apps MUST carry the entitlement for TCC to
  prompt. Earlier macOS versions were more lenient.
- **`tccutil reset All <bundle-id>`** resets all services at once.
- **TCC database auth_value**: 0 = denied, 2 = allowed, 3 = limited
  (Contacts-only on iOS; on macOS `limited` is not used as of macOS 26).

## Verification

To confirm an entitlement is correctly applied to a signed binary:

```bash
codesign -d --entitlements - /path/to/App.app 2>&1 | grep addressbook
```

To see what tccd expects when a request fails:

```bash
/usr/bin/log stream --predicate 'subsystem == "com.apple.TCC"' --timeout 30
```

Look for: `requires entitlement <expected-key> but it is missing`.

## Apple Documentation URLs

Append to `https://developer.apple.com/documentation/`:

- Contacts entitlement: `bundleresources/entitlements/com_apple_security_personal-information_addressbook`
- Calendars entitlement: `bundleresources/entitlements/com_apple_security_personal-information_calendars`
- Reminders entitlement: `bundleresources/entitlements/com_apple_security_personal-information_reminders`
- Photos entitlement: `bundleresources/entitlements/com_apple_security_personal-information_photos-library`
- Camera entitlement: `bundleresources/entitlements/com_apple_security_device_camera`
- Microphone entitlement: `bundleresources/entitlements/com_apple_security_device_microphone`
