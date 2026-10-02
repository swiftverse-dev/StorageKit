//
//  Keystore+SecureEnclaveKeyTests.swift
//  StorageKitTests
//
//  The algorithms also work with software P-256 keys, so these tests run on
//  every platform without a Secure Enclave.
//

import Foundation
import Testing
@testable import StorageKit

struct KeystoreSecureEnclaveKeyTests {

    private let plaintext = Data("vault key".utf8)

    @Test func `encrypt then decrypt returns the original data`() throws {
        let key = try makeKey()

        let ciphertext = try Keystore.SecureEnclaveKey.encrypt(plaintext, for: key.publicKey)

        #expect(ciphertext != plaintext)
        #expect(try key.decrypt(ciphertext) == plaintext)
    }

    @Test func `decrypt throws decryptionError for a tampered ciphertext`() throws {
        let key = try makeKey()
        var ciphertext = try Keystore.SecureEnclaveKey.encrypt(plaintext, for: key.publicKey)
        ciphertext[ciphertext.count - 1] ^= 0xFF

        #expect(throws: Keystore.Error.decryptionError) {
            try key.decrypt(ciphertext)
        }
    }

    @Test func `decrypt throws decryptionError for data that is not a ciphertext`() throws {
        let key = try makeKey()

        #expect(throws: Keystore.Error.decryptionError) {
            try key.decrypt(Data("garbage".utf8))
        }
    }

    @Test func `encrypt throws encryptionError for an RSA public key`() throws {
        let rsaPublicKey = try Keystore.keyFrom(.public(.rsa, data: KeyFixtures.publicX509))

        #expect(throws: Keystore.Error.encryptionError) {
            try Keystore.SecureEnclaveKey.encrypt(plaintext, for: rsaPublicKey)
        }
    }

    @Test func `sign then verify accepts the signature`() throws {
        let key = try makeKey()

        let signature = try key.sign(plaintext)

        #expect(Keystore.SecureEnclaveKey.verify(signature, of: plaintext, with: key.publicKey))
    }

    @Test func `verify rejects a signature over changed data`() throws {
        let key = try makeKey()
        let signature = try key.sign(plaintext)

        #expect(!Keystore.SecureEnclaveKey.verify(signature, of: Data("changed".utf8), with: key.publicKey))
    }

    @Test func `the public key matches the private key`() throws {
        let key = try makeKey()

        #expect(key.publicKey.data == (try Keystore.extractPublicKey(from: key.privateKey)).data)
    }

    @Test func `a crypto failure keeps only cancel and authentication codes`() {
        #expect(Keystore.Error(cryptoFailureCode: Int(errSecUserCanceled), fallback: .signingError)
                == .keychainError(.userCancelOperation))
        #expect(Keystore.Error(cryptoFailureCode: Int(errSecAuthFailed), fallback: .signingError)
                == .keychainError(.authenticationFailure))
        #expect(Keystore.Error(cryptoFailureCode: Int(errSecParam), fallback: .signingError)
                == .signingError)
    }
}

private extension KeystoreSecureEnclaveKeyTests {
    func makeKey() throws -> Keystore.SecureEnclaveKey {
        try Keystore.SecureEnclaveKey(privateKey: Keystore.generate(key: .ecPrimeRandom(bitSize: 256)))
    }
}
