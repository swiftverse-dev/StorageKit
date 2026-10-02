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
}

private extension KeystoreIntegrationTests {
    func makeSUT() -> Keystore.StandardVault {
        Keystore.StandardVault(storeId: "test.keystore.integration.\(runId)", protection: .whenUnlocked)
    }
}
