# Running StorageKit tests

StorageKit has two automated test surfaces plus one manual smoke step.

## 1. Unit tests — `swift test`

The SPM test target `StorageKitTests` covers everything that doesn't need a
real `SecItem*` round-trip: query construction, error translation, tag
mapping, `clear()` filtering, biometric policy gating (against `StubLAContext`),
`reuseContext` modes, and the pure-Foundation storages (`UserDefaults`,
`EncryptedFileStorage`).

```bash
swift test
```

Runs on macOS host with no Xcode, no simulator. Fast (< 1 s on a current Mac).

## 2. Integration tests — `xcodebuild test`

The host-app target `StorageKitTestApp` and its bundle `StorageKitTestAppTests`
exercise real `SecItem*` round-trips against the host app's keychain partition.
Required for end-to-end coverage on both iOS and macOS.

### iOS Simulator

```bash
xcodebuild -project StorageKitTestApp/StorageKitTestApp.xcodeproj \
    -scheme StorageKitTestApp \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    test
```

Pick any installed simulator name; check `xcrun simctl list devices available iOS`
if `iPhone 17` is unavailable.

### macOS

```bash
xcodebuild -project StorageKitTestApp/StorageKitTestApp.xcodeproj \
    -scheme StorageKitTestApp \
    -destination 'platform=macOS' \
    test
```

The macOS run depends on the `keychain-access-groups` entitlement on the host
app (already configured). If it fails with `errSecMissingEntitlement` (-34018),
verify the team ID in `StorageKitTestApp/StorageKitTestApp.entitlements` matches
your signing team. First-run code-signing may need `-allowProvisioningUpdates`.

## 3. Biometric storage — manual smoke step (only when modifying `KeychainBiometricStorage`)

`KeychainBiometricStorage` saves trigger a system biometric prompt on read.
The prompt is owned by iOS / macOS, not the app, so XCTest cannot dismiss it
automatically without UI-test plumbing — out of scope for this project.

The policy-gating logic (when `canEvaluatePolicy` returns false) is unit-tested
in `KeychainBiometricGatingTests` via `StubLAContext` and runs as part of
`swift test`. The remaining "does the biometric round-trip work end-to-end"
question is best answered with a one-off manual smoke.

### Recommended manual smoke

1. Open `StorageKitTestApp` in Xcode and run on a real iOS device with
   Touch ID or Face ID enrolled.
2. The app's main view shows an "Authenticate" button (`StorageKitTestApp.swift`).
   Tap it.
3. Approve the biometric prompt.
4. Watch the console: you should see the saved values being read back.

If you don't have a real device, the iOS Simulator can simulate biometry via
`Device → Face ID / Touch ID → Enrolled` + `Matching Face` for a manual check.

This step is only needed when changing `KeychainBiometricStorage` itself or
the `kSecAttrAccessControl` handling in `Keychain+Query.swift`. Day-to-day
work does not require it.

## Toolchain & deployment

StorageKit targets **Swift 6 / iOS 16 / macOS 13** and builds in the Swift 6
language mode. Building the package requires Xcode 16+ / a Swift 6 toolchain.

### Breaking changes (since the Swift 5 release)

- `Keychain.promptMessage` and `Keychain.reuseContext` are now immutable; set them
  via the initializer (`promptMessage:` / `reuseContext:`) instead of assigning
  after construction.
- `KeychainBiometricStorage.reusingContext(_:)` was removed — pass
  `reuseContextMode:` to the initializer.
- Minimum deployment raised from iOS 13 / macOS 11 to iOS 16 / macOS 13.
