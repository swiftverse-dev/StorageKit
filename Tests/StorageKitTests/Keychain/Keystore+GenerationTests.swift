//
//  Keystore+GenerationTests.swift
//  StorageKitTests
//

import Foundation
import Testing
@testable import StorageKit

final class KeystoreGenerationTests: LeakTrackingTestCase {

    @Test func `generation puts the access control in the private key attributes`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)

        _ = try sut.generate(key: .ecPrimeRandom(bitSize: 256), forTag: "tag1")

        let attributes = try #require(fake.generatedKeyAttributes.first)
        #expect(attributes[kSecAttrAccessControl as String] == nil)
        let privateAttributes = try #require(attributes[kSecPrivateKeyAttrs as String] as? [String: Any])
        #expect(privateAttributes[kSecAttrAccessControl as String] != nil)
        #expect(privateAttributes[kSecAttrApplicationTag as String] as? String == "test.keystore.tag1")
        #expect(privateAttributes[kSecAttrIsPermanent as String] as? Bool == true)
        #expect(attributes[kSecAttrTokenID as String] == nil)
    }

    @Test func `generation without a tag does not make the key permanent`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)

        _ = try sut.generate(key: .ecPrimeRandom(bitSize: 256))

        let attributes = try #require(fake.generatedKeyAttributes.first)
        let privateAttributes = try #require(attributes[kSecPrivateKeyAttrs as String] as? [String: Any])
        #expect(privateAttributes[kSecAttrIsPermanent as String] == nil)
        #expect(fake.items.isEmpty)
    }

    @Test func `a failed policy check keeps the existing key`() throws {
        let fake = InMemoryKeychain()
        let context = StubLAContext()
        let sut = makeSUT(performer: fake, accessControl: .passcode, context: context)
        _ = try sut.generate(key: .ecPrimeRandom(bitSize: 256), forTag: "tag1")

        context.canEvaluateResult = false

        #expect(throws: Keychain.Error.passcodeDisabled) {
            try sut.generate(key: .ecPrimeRandom(bitSize: 256), forTag: "tag1")
        }
        #expect(fake.items.count == 1)
    }
}

private extension KeystoreGenerationTests {
    func makeSUT(
        performer: any KeychainPerforming,
        accessControl: Keystore.AccessControl = .none,
        context: StubLAContext = StubLAContext()
    ) -> Keystore.StandardVault {
        let sut = KeychainSUTFactory.makeKeystore(
            accessControl: accessControl,
            performer: performer,
            contextFactory: { context }
        )
        trackForMemoryLeaks(sut)
        return sut
    }
}
