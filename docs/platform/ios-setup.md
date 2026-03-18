# iOS Platform Setup — Drone Commander

## Environment Requirements

| Tool | Minimum | Tested |
|------|---------|--------|
| Flutter | 3.41+ | 3.41.2 |
| Xcode | 26.0+ | 26.2 |
| CocoaPods | 1.16+ | 1.16.2 |
| iOS Deployment Target | **16.0** | — |

## Configuration Summary

| Setting | Value |
|---------|-------|
| Bundle ID | `com.ob3.dronecommander` |
| Display Name | Drone Commander |
| Orientation | Portrait only |
| Status Bar | Light content (dark background) |
| Platform | iOS 16.0+ |

## Building for Simulator

```bash
# Debug build (no code signing required)
cd /Users/ozgur/Documents/OB3
flutter run -d "iPhone 16 Pro"
```

## Building for Device

Requires Apple Developer account and signing configuration:

```bash
# 1. Open Xcode and set your signing team
open ios/Runner.xcworkspace

# 2. In Xcode → Runner → Signing & Capabilities:
#    - Select your Development Team
#    - Xcode auto-manages provisioning profiles

# 3. Build via Flutter
flutter run -d <device-id>
```

## Archiving for TestFlight / App Store

```bash
# 1. Build release IPA
flutter build ipa --release

# 2. The archive is at:
#    build/ios/archive/Runner.xcarchive

# 3. Upload via Xcode Organizer or:
xcrun altool --upload-app -f build/ios/ipa/drone_commander.ipa \
  -t ios \
  -u "your@apple.id" \
  -p "@keychain:AC_PASSWORD"
```

## App Store Connect Checklist

- [ ] App name: "Drone Commander"
- [ ] Bundle ID: `com.ob3.dronecommander`
- [ ] Category: Games → Strategy
- [ ] Age Rating: 12+ (Infrequent/Mild Realistic Violence — military combat theme)
- [ ] Privacy Policy URL
- [ ] App screenshots (6.7" and 6.1" iPhone required)
- [ ] App description and keywords
- [ ] Support URL
- [ ] App icon (1024×1024 without alpha)

## Known Constraints

- **No Android target yet** — add later with `flutter create --platforms android .`
- **Code signing** — not configured; requires Apple Developer Program enrollment
- **App Icons** — placeholder; UI Designer will provide final assets
