//
//  Keystore+InstanceTests.swift
//  StorageKitTests
//

import Foundation
import Testing
@testable import StorageKit

final class KeystoreInstanceTests: LeakTrackingTestCase {

    @Test func `loadKey throws itemNotFound for an unknown tag`() {
        let sut = makeSUT(performer: InMemoryKeychain())

        #expect(throws: Keystore.Error.keychainError(.itemNotFound)) {
            try sut.loadKey(for: "unknown")
        }
    }

    @Test func `deleteKey returns false for an unknown tag`() {
        let sut = makeSUT(performer: InMemoryKeychain())

        #expect(sut.deleteKey(for: "unknown") == false)
    }

    @Test func `storing a private key uses the prefixed application tag`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(storeId: "test.keystore", performer: fake)

        _ = try sut.keyFrom(.private(.rsa, data: KeyFixtures.privatePkcs1Base64), storingWithTag: "knownTag")

        #expect(fake.items.count == 1)
        let stored = try #require(fake.items.values.first)
        #expect(stored[kSecAttrApplicationTag as String] as? String == "test.keystore.knownTag")
        #expect(stored[kSecClass as String] as? String == kSecClassKey as String)
    }

    @Test func `storing a public key does not touch the keychain`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(storeId: "test.keystore", performer: fake)

        _ = try sut.keyFrom(.public(.rsa, data: KeyFixtures.publicX509), storingWithTag: "knownTag")

        #expect(fake.items.isEmpty)
    }

    @Test func `loadKey finds an EC key by tag`() throws {
        let sut = makeSUT(performer: InMemoryKeychain())
        let generated = try sut.generate(key: .ecPrimeRandom(bitSize: 256), forTag: "ec")

        let loaded = try sut.loadKey(for: "ec")

        #expect(loaded.data == generated.data)
    }

    @Test func `deleteKey removes an EC key`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)
        _ = try sut.generate(key: .ecPrimeRandom(bitSize: 256), forTag: "ec")

        #expect(sut.deleteKey(for: "ec"))
        #expect(fake.items.isEmpty)
    }

    @Test func `loadKey throws itemNotFound when the result is not a key`() {
        let fake = InMemoryKeychain()
        fake.copyResultOverride = "not a key" as CFString
        let sut = makeSUT(performer: fake)

        #expect(throws: Keystore.Error.keychainError(.itemNotFound)) {
            try sut.loadKey(for: "any")
        }
    }

    @Test func `loadKey still checks the biometric policy`() {
        let context = StubLAContext()
        context.canEvaluateResult = false
        let sut = KeychainSUTFactory.makeKeystore(
            accessControl: .currentBiometry,
            performer: InMemoryKeychain(),
            contextFactory: { context }
        )
        trackForMemoryLeaks(sut)

        #expect(throws: Keychain.Error.biometryDisabled) {
            try sut.loadKey(for: "any")
        }
    }
}

private extension KeystoreInstanceTests {
    func makeSUT(storeId: String = "test.keystore", performer: any KeychainPerforming) -> Keystore.StandardVault {
        let sut = KeychainSUTFactory.makeKeystore(storeId: storeId, performer: performer)
        trackForMemoryLeaks(sut)
        return sut
    }
}
