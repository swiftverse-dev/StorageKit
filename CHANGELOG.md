# Changelog

All notable changes to StorageKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once it reaches 1.0. While the package is pre-1.0, minor-version bumps may
contain breaking changes.

## [Unreleased]

### Added
- `accessGroup: String?` parameter on `Keychain` and all subclass initializers.
  When provided, keychain items are written to (and read from) the specified
  access group via `kSecAttrAccessGroup`.
- `Keystore.default` and `Keystore.defaultStoreId` are now `public`.

### Changed
- **iOS deployment target raised from 12.0 to 13.0.** Required to enable
  `kSecUseDataProtectionKeychain`, which is the supported keychain on macOS.
- **`KeychainStorage` is now locked to `kSecClassGenericPassword`.** The
  `itemClass` parameter on `KeychainStorage`'s internal initializer has been
  removed; the public initializer retains the parameter for source
  compatibility but always forwards `kSecClassGenericPassword` to the base
  class. All keychain storage in the `KeychainStorage` family now uses
  generic-password items.
- **`KeychainStorage` namespaces items by `kSecAttrService = storeId`.** Items
  are stored with `kSecAttrAccount = tag` (raw tag, no `storeId.` prefix) and
  `kSecAttrService = storeId`. `clear()` is now a single `SecItemDelete`
  scoped by `{ class, service }` — biometric storages no longer prompt during
  `clear()`.
- macOS keychain queries now set `kSecUseDataProtectionKeychain = true`,
  enabling the iOS-style data-protection keychain partition. Consuming apps
  on macOS must declare `keychain-access-groups` in their entitlements.
- `KeychainBiometricStorage.reuseContextMode` property has been removed.
  Callers should use the inherited `reuseContext` property (same type) or
  the fluent `reusingContext(_:)` builder (still present).
- `KeychainBiometricStorage` no longer uses `kSecClassInternetPassword`
  internally — it shares the unified generic-password schema with
  `KeychainEncryptedStorage`. Isolation between the two storages is preserved
  via their distinct `kSecAttrService` namespaces.
- `Keychain.context` is now an `internal var` of type `LAContextProviding`
  (previously `public var` of type `LAContext`). The property was always
  used only inside the library; the type change is part of the new
  `LAContextProviding` testing seam.

### Fixed
- Corrected the platform conditional in `Keychain.Query.createQueryForDataRetrieve`
  and `Keystore.Query.createQueryForKeyRetrieve`. The previous `#if TARGET_OS_IPHONE`
  was a C preprocessor macro that Swift's `#if` cannot see, so the wrong
  branch ran on every platform — assigning `kSecUseAuthenticationContext`
  instead of `kSecUseOperationPrompt` on iOS. Now uses `#if os(iOS)`.

### Removed
- `KeychainBiometricStorage.reuseContextMode` property (use `reuseContext`).

### Migration notes
Pre-existing keychain items stored by earlier versions of StorageKit use the
old schema (`kSecAttrAccount = "\(storeId).\(tag)"`, no `kSecAttrService`)
and are not reachable through the new API. The library is pre-1.0; no
automatic migration is provided. Affected apps should clear their old
items via the previous version's API before upgrading.
