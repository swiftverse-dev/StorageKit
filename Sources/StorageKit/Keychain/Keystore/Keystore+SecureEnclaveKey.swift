//
//  Keystore+SecureEnclaveKey.swift
//  StorageKit
//

import Foundation

public extension Keystore {
    /// A P-256 key pair whose private key lives in the Secure Enclave.
    /// The algorithms are fixed, so a call cannot pick one the key does not support.
    struct SecureEnclaveKey: @unchecked Sendable {
        public let privateKey: SecKey
        public let publicKey: SecKey

        internal init(privateKey: SecKey) throws {
            self.privateKey = privateKey
            self.publicKey = try Keystore.Operation.extractPublicKey(from: privateKey)
        }
    }
}

public extension Keystore.SecureEnclaveKey {
    /// Decrypts data made by `encrypt(_:for:)`. Prompts for authentication
    /// when the key has an access control.
    func decrypt(_ data: Data) throws -> Data {
        try Keystore.Operation.performCrypto(failure: .decryptionError) {
            SecKeyCreateDecryptedData(privateKey, Self.encryptionAlgorithm, data as CFData, $0)
        }
    }

    /// Signs data with ECDSA SHA-256. Prompts for authentication when the key
    /// has an access control.
    func sign(_ data: Data) throws -> Data {
        try Keystore.Operation.performCrypto(failure: .signingError) {
            SecKeyCreateSignature(privateKey, Self.signatureAlgorithm, data as CFData, $0)
        }
    }

    /// Encrypts data for the holder of the private key that matches `publicKey`.
    static func encrypt(_ data: Data, for publicKey: SecKey) throws -> Data {
        try Keystore.Operation.performCrypto(failure: .encryptionError) {
            SecKeyCreateEncryptedData(publicKey, encryptionAlgorithm, data as CFData, $0)
        }
    }

    /// Returns `true` when `signature` is a valid signature of `data` by the
    /// private key that matches `publicKey`.
    static func verify(_ signature: Data, of data: Data, with publicKey: SecKey) -> Bool {
        SecKeyVerifySignature(publicKey, signatureAlgorithm, data as CFData, signature as CFData, nil)
    }
}

extension Keystore.SecureEnclaveKey {
    static var encryptionAlgorithm: SecKeyAlgorithm { .eciesEncryptionCofactorVariableIVX963SHA256AESGCM }
    static var signatureAlgorithm: SecKeyAlgorithm { .ecdsaSignatureMessageX962SHA256 }
}
