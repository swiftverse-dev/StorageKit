//
//  KeystoreStaticTests.swift
//  StorageKitTests
//

import Foundation
import Testing
import StorageKit

// Static API only — nothing is retained past the test, so no leak tracking.
struct KeystoreStaticTests {

    // MARK: generate(key:) — static, no keychain side effects

    @Test func `generate throws badKeySizeError on an invalid key size`() {
        for key in invalidKeys {
            expect(error: .badKeySizeError) {
                try Keystore.generate(key: key)
            }
        }
    }

    @Test func `generate succeeds on a valid key size`() {
        for key in validKeys {
            expect(error: nil) {
                try Keystore.generate(key: key)
            }
        }
    }

    // MARK: keyFrom(_:) — pure SecKey parsing

    @Test func `keyFrom throws parsingError for wrong key data`() {
        let wrongKeyData = Data("wrong key data".utf8)

        expect(error: .parsingError) {
            try Keystore.keyFrom(.private(.rsa, data: wrongKeyData))
        }

        expect(error: .parsingError) {
            try Keystore.keyFrom(.public(.rsa, data: wrongKeyData))
        }
    }

    @Test func `keyFrom succeeds on a valid private key`() {
        expect(error: nil) {
            try Keystore.keyFrom(.private(.rsa, data: KeyFixtures.privatePkcs1Base64))
        }
    }

    @Test func `keyFrom succeeds on a valid public key`() {
        expect(error: nil) {
            try Keystore.keyFrom(.public(.rsa, data: KeyFixtures.publicX509))
        }
    }

    // MARK: extractPublicKey(from:)

    @Test func `extractPublicKey succeeds for a valid private key`() throws {
        let priv = try Keystore.keyFrom(.private(.rsa, data: KeyFixtures.privatePkcs1Base64))

        _ = try Keystore.extractPublicKey(from: priv)
    }
}

private extension KeystoreStaticTests {

    var validKeys: [Keystore.KeyTypeGeneration] {
        [.rsa(bitSize: 1024), .ecPrimeRandom(bitSize: 192)]
    }

    var invalidKeys: [Keystore.KeyTypeGeneration] {
        [.rsa(bitSize: 1), .ecPrimeRandom(bitSize: 1)]
    }

    func expect(
        error: Keystore.Error?,
        whileExecuting block: () throws -> Any,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        do {
            let result = try block()
            if let error {
                Issue.record("Expected \(error), got \(result) instead", sourceLocation: sourceLocation)
            }
        } catch let caughtError {
            guard let error else {
                Issue.record("Expected nil, got \(caughtError) instead", sourceLocation: sourceLocation)
                return
            }
            #expect(caughtError as? Keystore.Error == error, sourceLocation: sourceLocation)
        }
    }
}
