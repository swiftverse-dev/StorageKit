//
//  Keystore+SecureEnclaveVault.swift
//  StorageKit
//

import CryptoKit
import Foundation
import LocalAuthentication

public extension Keystore.Vault where B == Keystore.SecureEnclave {
    /// `false` on devices and Macs without a Secure Enclave.
    static var isAvailable: Bool {
        CryptoKit.SecureEnclave.isAvailable
    }

    convenience init(
        storeId: String,
        protection: Keystore.SecureEnclaveProtection = .whenThisDeviceUnlocked,
        accessControl: Keystore.AccessControl = .none,
        accessGroup: String? = nil,
        promptMessage: String? = nil,
        reuseContext: Keychain.ReuseContextMode = .never
    ) {
        self.init(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContext,
            performer: SecItemPerformer(),
            contextFactory: { LAContext() },
            clock: ContinuousClock(),
            secureEnclaveAvailability: { CryptoKit.SecureEnclave.isAvailable }
        )
    }

    /// Creates a P-256 key in the Secure Enclave and stores it under `tag`.
    /// Replaces any key already stored under `tag`.
    func generateKey(forTag tag: String) throws -> Keystore.SecureEnclaveKey {
        guard secureEnclaveAvailability() else {
            throw Keystore.Error.secureEnclaveUnavailable
        }
        let mappedTag = map(tag: tag)

        // Build the query first: it runs the policy check, and a failed check
        // must not delete the key that is already stored.
        let query = try Keystore.Query.createQueryForKeyGeneration(
            key: .ecPrimeRandom(bitSize: 256),
            tag: mappedTag,
            context: promptedContext(),
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup,
            tokenID: kSecAttrTokenIDSecureEnclave
        )

        deleteKey(mappedTag: mappedTag)
        let privateKey = try Keystore.Operation.generatePrivateKey(using: query, with: performer)
        return try Keystore.SecureEnclaveKey(privateKey: privateKey)
    }

    /// Loads the key stored under `tag`. Authentication happens later, when
    /// the key decrypts or signs.
    func loadKey(for tag: String) throws -> Keystore.SecureEnclaveKey {
        let privateKey = try loadPrivateKey(for: tag, context: promptedContext(), promptMessage: nil)
        return try Keystore.SecureEnclaveKey(privateKey: privateKey)
    }
}

extension Keystore.Vault where B == Keystore.SecureEnclave {
    convenience init(
        storeId: String,
        protection: Keystore.SecureEnclaveProtection,
        accessControl: Keystore.AccessControl,
        accessGroup: String?,
        promptMessage: String?,
        reuseContext: Keychain.ReuseContextMode,
        performer: any KeychainPerforming,
        contextFactory: @escaping @Sendable () -> any LAContextProviding,
        clock: any Clock<Duration>,
        secureEnclaveAvailability: @escaping @Sendable () -> Bool
    ) {
        self.init(
            storeId: storeId,
            protection: protection.protection,
            accessControlFlags: accessControl.flags.union(.privateKeyUsage),
            policy: accessControl.policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContext,
            performer: performer,
            contextFactory: contextFactory,
            clock: clock,
            secureEnclaveAvailability: secureEnclaveAvailability
        )
    }

    /// The Secure Enclave prompts when the key is used, not when it is loaded.
    /// The key keeps the context from its query, so the message goes on that
    /// context. Read `self.context` once: with `.never` reuse, every read makes
    /// a new context.
    private func promptedContext() -> any LAContextProviding {
        let context = self.context
        if let promptMessage {
            context.localizedReason = promptMessage
        }
        return context
    }
}
