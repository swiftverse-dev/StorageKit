//
//  Keystore+Vault.swift
//  StorageKit
//

import Foundation
import LocalAuthentication

public extension Keystore {
    /// Stores private keys by tag. `B` picks the API: `Keystore.Standard` for
    /// software keys, `Keystore.SecureEnclave` for Secure Enclave keys.
    final class Vault<B: Backing>: Keychain, @unchecked Sendable {

        init(
            storeId: String,
            protection: Keychain.Protection,
            accessControlFlags: Keychain.AccessControl,
            policy: LAPolicy?,
            accessGroup: String?,
            promptMessage: String?,
            reuseContext: Keychain.ReuseContextMode,
            performer: any KeychainPerforming,
            contextFactory: @escaping @Sendable () -> any LAContextProviding,
            clock: any Clock<Duration>
        ) {
            super.init(
                storeId: storeId,
                protection: protection,
                accessControl: accessControlFlags,
                policy: policy,
                itemClass: kSecClassKey,
                accessGroup: accessGroup,
                promptMessage: promptMessage,
                reuseContext: reuseContext,
                performer: performer,
                contextFactory: contextFactory,
                clock: clock
            )
        }
    }
}

public extension Keystore.Vault {
    @discardableResult
    func deleteKey(for tag: String) -> Bool {
        deleteKey(mappedTag: map(tag: tag))
    }
}

extension Keystore.Vault {
    func map(tag: String) -> String {
        "\(storeId).\(tag)"
    }

    @discardableResult
    func deleteKey(mappedTag: String) -> Bool {
        let query = Keystore.Query.createQueryForKeyDeletion(
            .rsa,
            tag: mappedTag,
            itemClass: itemClass,
            accessGroup: accessGroup
        )
        return Keystore.Operation.deleteItem(using: query, with: performer)
    }

    func loadPrivateKey(
        for tag: String,
        context: any LAContextProviding,
        promptMessage: String?
    ) throws -> SecKey {
        let query = try Keystore.Query.createQueryForKeyRetrieve(
            .rsa,
            tag: map(tag: tag),
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage
        )
        return try Keystore.Operation.loadPrivateKey(using: query, with: performer)
    }
}
