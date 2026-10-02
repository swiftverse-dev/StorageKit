//
//  InMemoryKeychain.swift
//  StorageKitTests
//

import Foundation
@testable import StorageKit

/// In-memory fake of `KeychainPerforming` for unit tests.
/// Stores items as attribute dictionaries keyed by (class, primaryKey)
/// where primaryKey is `kSecAttrAccount` for password classes and
/// `kSecAttrApplicationTag` for `kSecClassKey`.
final class InMemoryKeychain: KeychainPerforming {

    private(set) var items: [Key: [String: Any]] = [:]

    /// Every attribute dictionary passed to `createRandomKey`, in call order.
    private(set) var generatedKeyAttributes: [[String: Any]] = []

    /// Override-able status injectors for failure-mode tests.
    var addStatusOverride: OSStatus?
    var copyStatusOverride: OSStatus?
    var deleteStatusOverride: OSStatus?
    var updateStatusOverride: OSStatus?

    /// When set, `copyMatching` succeeds and returns this value as the result.
    var copyResultOverride: CFTypeRef?

    struct Key: Hashable {
        let itemClass: String
        let primaryKey: String
    }

    // MARK: KeychainPerforming

    func add(_ query: CFDictionary) -> OSStatus {
        if let override = addStatusOverride { return override }
        let dict = query as! [String: Any]
        guard let key = Self.makeKey(from: dict) else { return errSecParam }
        if items[key] != nil { return errSecDuplicateItem }
        items[key] = dict
        return errSecSuccess
    }

    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if let override = copyStatusOverride { return override }
        if let copyResultOverride {
            result?.pointee = copyResultOverride
            return errSecSuccess
        }
        let dict = query as! [String: Any]
        let matchLimit = (dict[kSecMatchLimit as String] as? String) ?? (kSecMatchLimitOne as String)
        let returnAttributes = (dict[kSecReturnAttributes as String] as? Bool) ?? false
        let returnData = (dict[kSecReturnData as String] as? Bool) ?? false
        let returnRef = (dict[kSecReturnRef as String] as? Bool) ?? false

        let matches = items.filter { Self.matches(stored: $0.value, query: dict) }

        if matchLimit == (kSecMatchLimitAll as String) {
            if matches.isEmpty { return errSecItemNotFound }
            let attrs = matches.map { $0.value }
            result?.pointee = attrs as CFArray
            return errSecSuccess
        }

        guard let first = matches.first else { return errSecItemNotFound }
        if returnAttributes {
            result?.pointee = first.value as CFDictionary
        } else if returnData {
            result?.pointee = (first.value[kSecValueData as String] as? Data) as CFTypeRef?
        } else if returnRef {
            result?.pointee = first.value[kSecValueRef as String] as CFTypeRef?
        } else {
            result?.pointee = first.value as CFDictionary
        }
        return errSecSuccess
    }

    func update(_ query: CFDictionary, attributes: CFDictionary) -> OSStatus {
        if let override = updateStatusOverride { return override }
        let qdict = query as! [String: Any]
        let attrs = attributes as! [String: Any]
        let matches = items.filter { Self.matches(stored: $0.value, query: qdict) }
        if matches.isEmpty { return errSecItemNotFound }
        for (key, var stored) in matches {
            for (k, v) in attrs { stored[k] = v }
            items[key] = stored
        }
        return errSecSuccess
    }

    func delete(_ query: CFDictionary) -> OSStatus {
        if let override = deleteStatusOverride { return override }
        let dict = query as! [String: Any]
        let matches = items.filter { Self.matches(stored: $0.value, query: dict) }
        if matches.isEmpty { return errSecItemNotFound }
        for key in matches.keys { items.removeValue(forKey: key) }
        return errSecSuccess
    }

    /// Creates a real software key of the requested type and size, ignoring
    /// `kSecAttrTokenID`. A permanent key is stored under its tag with
    /// `kSecValueRef`, so `loadKey` can return it.
    func createRandomKey(_ attributes: CFDictionary, error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey? {
        let dict = attributes as! [String: Any]
        generatedKeyAttributes.append(dict)

        let softwareAttributes: [String: Any] = [
            kSecAttrKeyType as String: dict[kSecAttrKeyType as String] as Any,
            kSecAttrKeySizeInBits as String: dict[kSecAttrKeySizeInBits as String] as Any,
        ]
        guard let key = SecKeyCreateRandomKey(softwareAttributes as CFDictionary, error) else { return nil }

        let privateAttributes = dict[kSecPrivateKeyAttrs as String] as? [String: Any] ?? [:]
        if privateAttributes[kSecAttrIsPermanent as String] as? Bool == true,
           let tag = privateAttributes[kSecAttrApplicationTag as String] as? String {
            var stored: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: tag,
                kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                kSecAttrKeyType as String: dict[kSecAttrKeyType as String] as Any,
                kSecValueRef as String: key,
            ]
            stored[kSecAttrAccessGroup as String] = dict[kSecAttrAccessGroup as String]
            items[Key(itemClass: kSecClassKey as String, primaryKey: tag)] = stored
        }
        return key
    }

    // MARK: Matching

    private static func makeKey(from dict: [String: Any]) -> Key? {
        guard let itemClass = dict[kSecClass as String] as? String else { return nil }
        if itemClass == (kSecClassKey as String) {
            guard let tag = dict[kSecAttrApplicationTag as String] as? String else { return nil }
            return Key(itemClass: itemClass, primaryKey: tag)
        }
        let service = dict[kSecAttrService as String] as? String ?? ""
        let account = dict[kSecAttrAccount as String] as? String ?? ""
        return Key(itemClass: itemClass, primaryKey: "\(service)|\(account)")
    }

    /// A stored item matches a query iff every attribute the query specifies
    /// (excluding `kSecReturn*`, `kSecMatchLimit`, `kSecUseAuthenticationContext`,
    /// `kSecUseDataProtectionKeychain`, `kSecAttrAccessControl`) is present and
    /// equal on the stored item.
    private static func matches(stored: [String: Any], query: [String: Any]) -> Bool {
        var ignored: Set<String> = [
            kSecReturnData as String,
            kSecReturnAttributes as String,
            kSecReturnRef as String,
            kSecReturnPersistentRef as String,
            kSecMatchLimit as String,
            kSecUseAuthenticationContext as String,
            kSecUseDataProtectionKeychain as String,
            kSecAttrAccessControl as String,
            kSecValueData as String,
            kSecPrivateKeyAttrs as String,
            kSecAttrKeySizeInBits as String,
            kSecAttrIsPermanent as String,
        ]
        #if !os(macOS)
        // `kSecUseOperationPrompt` is set by the production query builders
        // only under `#if os(iOS)`, and is deprecated on macOS — skip it from
        // the ignored set on macOS so we don't reference the deprecated symbol
        // on a platform where it would never appear in a query.
        ignored.insert(kSecUseOperationPrompt as String)
        #endif
        for (key, value) in query where !ignored.contains(key) {
            guard let storedValue = stored[key] else { return false }
            if let s = value as? String, let r = storedValue as? String {
                if s != r { return false }
            } else {
                // Best-effort equality fallback — coerce to strings.
                if "\(value)" != "\(storedValue)" { return false }
            }
        }
        return true
    }
}
