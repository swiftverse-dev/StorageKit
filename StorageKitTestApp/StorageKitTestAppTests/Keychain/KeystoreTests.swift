//
//  KeystoreTests.swift
//  StorageKitTestAppTests
//
//  Integration tests — exercise real SecKey generation and keychain round-trips.
//

import Foundation
import Testing
import StorageKit

final class KeystoreIntegrationTests {

    // Real keychain, parallel tests: each one gets its own store so the shared
    // `knownTag` can't collide.
    private let runId = UUID().uuidString.prefix(8)

    @Test func `generating a key with a tag stores and loads it`() throws {
        let sut = makeSUT()
        defer { sut.deleteKey(for: "knownTag") }

        _ = try sut.generate(key: .rsa, forTag: "knownTag")
        _ = try sut.loadKey(for: "knownTag")
    }

    @Test func `generating a key with a tag overrides the previously stored key`() throws {
        let sut = makeSUT()
        defer { sut.deleteKey(for: "knownTag") }

        let first = try sut.generate(key: .rsa, forTag: "knownTag")
        let second = try sut.generate(key: .rsa, forTag: "knownTag")

        #expect(first.data != second.data)
        let loaded = try sut.loadKey(for: "knownTag")
        #expect(loaded.data == second.data)
    }

    @Test func `loading an unknown tag throws`() {
        let sut = makeSUT()

        #expect(throws: (any Error).self) {
            try sut.loadKey(for: "unknownTag")
        }
    }

    @Test func `deleting an unknown tag returns false`() {
        let sut = makeSUT()

        #expect(sut.deleteKey(for: "unknownTag") == false)
    }

    @Test func `deleting a previously stored tag returns true`() throws {
        let sut = makeSUT()

        _ = try sut.generate(key: .rsa, forTag: "knownTag")

        #expect(sut.deleteKey(for: "knownTag"))
    }

    // The protection lives in the key's access control. If generation put the
    // access control where the keychain ignores it, the key would get the
    // default protection (`ak`, when unlocked) instead.
    @Test func `a generated key keeps the protection from its access control`() throws {
        let sut = Keystore.StandardVault(
            storeId: "test.keystore.integration.protection.\(runId)",
            protection: .afterFirstUnlock
        )
        defer { sut.deleteKey(for: "knownTag") }
        _ = try sut.generate(key: .ecPrimeRandom(bitSize: 256), forTag: "knownTag")

        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "\(sut.storeId).knownTag",
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        #expect(status == errSecSuccess)
        let attributes = try #require(result as? [String: Any])
        #expect(attributes[kSecAttrAccessible as String] as? String == kSecAttrAccessibleAfterFirstUnlock as String)
    }

    @Test func `an EC key loads and deletes by tag`() throws {
        let sut = makeSUT()
        let generated = try sut.generate(key: .ecPrimeRandom(bitSize: 256), forTag: "ecTag")

        #expect(try sut.loadKey(for: "ecTag").data == generated.data)
        #expect(sut.deleteKey(for: "ecTag"))
    }
}

private extension KeystoreIntegrationTests {
    func makeSUT() -> Keystore.StandardVault {
        Keystore.StandardVault(storeId: "test.keystore.integration.\(runId)", protection: .whenUnlocked)
    }
}
