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
}

private extension KeystoreInstanceTests {
    func makeSUT(storeId: String = "test.keystore", performer: any KeychainPerforming) -> Keystore {
        let sut = KeychainSUTFactory.makeKeystore(storeId: storeId, performer: performer)
        trackForMemoryLeaks(sut)
        return sut
    }
}
