//
//  Keystore+SecureEnclaveVaultTests.swift
//  StorageKitTests
//
//  The fake makes software keys, so these tests check the queries and the
//  vault logic. The real Secure Enclave runs in the integration tests.
//

import Foundation
import Testing
@testable import StorageKit

final class KeystoreSecureEnclaveVaultTests: LeakTrackingTestCase {

    @Test func `generateKey asks for a 256-bit EC key in the Secure Enclave`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)

        _ = try sut.generateKey(forTag: "tag1")

        let attributes = try #require(fake.generatedKeyAttributes.first)
        #expect(attributes[kSecAttrTokenID as String] as? String == kSecAttrTokenIDSecureEnclave as String)
        #expect(attributes[kSecAttrKeyType as String] as? String == kSecAttrKeyTypeECSECPrimeRandom as String)
        #expect(attributes[kSecAttrKeySizeInBits as String] as? Int == 256)
        #expect(attributes[kSecAttrAccessControl as String] == nil)
        let privateAttributes = try #require(attributes[kSecPrivateKeyAttrs as String] as? [String: Any])
        #expect(privateAttributes[kSecAttrIsPermanent as String] as? Bool == true)
        #expect(privateAttributes[kSecAttrApplicationTag as String] as? String == "test.secureenclave.keystore.tag1")
        #expect(privateAttributes[kSecAttrAccessControl as String] != nil)
    }

    @Test func `generateKey then loadKey returns the same key`() throws {
        let sut = makeSUT(performer: InMemoryKeychain())

        let generated = try sut.generateKey(forTag: "tag1")
        let loaded = try sut.loadKey(for: "tag1")

        #expect(loaded.publicKey.data == generated.publicKey.data)
    }

    @Test func `generateKey replaces the key with the same tag`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)

        _ = try sut.generateKey(forTag: "tag1")
        let second = try sut.generateKey(forTag: "tag1")

        #expect(fake.items.count == 1)
        #expect(try sut.loadKey(for: "tag1").publicKey.data == second.publicKey.data)
    }

    @Test func `deleteKey removes the key`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)
        _ = try sut.generateKey(forTag: "tag1")

        #expect(sut.deleteKey(for: "tag1"))
        #expect(fake.items.isEmpty)
    }

    @Test func `an unavailable Secure Enclave throws and keeps the existing key`() throws {
        let fake = InMemoryKeychain()
        _ = try makeSUT(performer: fake).generateKey(forTag: "tag1")
        let sut = makeSUT(performer: fake, isAvailable: false)

        #expect(throws: Keystore.Error.secureEnclaveUnavailable) {
            try sut.generateKey(forTag: "tag1")
        }
        #expect(fake.generatedKeyAttributes.count == 1)
        #expect(fake.items.count == 1)
    }

    @Test func `a failed policy check keeps the existing key`() throws {
        let fake = InMemoryKeychain()
        let context = StubLAContext()
        let sut = makeSUT(performer: fake, accessControl: .currentBiometry, context: context)
        _ = try sut.generateKey(forTag: "tag1")

        context.canEvaluateResult = false

        #expect(throws: Keychain.Error.biometryDisabled) {
            try sut.generateKey(forTag: "tag1")
        }
        #expect(fake.items.count == 1)
    }

    // A new context on every read, as with `.never` reuse: the message must
    // land on the context that reaches the query, not on another one.
    @Test func `loadKey puts the prompt message on the context it queries with`() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeSecureEnclaveVault(
            performer: fake,
            promptMessage: "Unlock your codes",
            contextFactory: { StubLAContext() }
        )
        trackForMemoryLeaks(sut)
        _ = try sut.generateKey(forTag: "tag1")

        _ = try sut.loadKey(for: "tag1")

        let query = try #require(fake.copyMatchingQueries.last)
        let context = try #require(query[kSecUseAuthenticationContext as String] as? StubLAContext)
        #expect(context.localizedReason == "Unlock your codes")
    }
}

private extension KeystoreSecureEnclaveVaultTests {
    func makeSUT(
        performer: any KeychainPerforming,
        accessControl: Keystore.AccessControl = .none,
        promptMessage: String? = nil,
        isAvailable: Bool = true,
        context: StubLAContext = StubLAContext()
    ) -> Keystore.SecureEnclaveVault {
        let sut = KeychainSUTFactory.makeSecureEnclaveVault(
            accessControl: accessControl,
            performer: performer,
            promptMessage: promptMessage,
            isAvailable: isAvailable,
            contextFactory: { context }
        )
        trackForMemoryLeaks(sut)
        return sut
    }
}
