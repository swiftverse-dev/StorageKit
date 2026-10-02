//
//  Keystore+StandardVault.swift
//  StorageKit
//

import Foundation
import LocalAuthentication

public extension Keystore.Vault where B == Keystore.Standard {
    convenience init(
        storeId: String,
        protection: Keychain.Protection,
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
            clock: ContinuousClock()
        )
    }

    func generate(key: Keystore.KeyTypeGeneration, forTag tag: String? = nil) throws -> SecKey {
        let mappedTag = tag.map(map(tag:))
        if let mappedTag { deleteKey(mappedTag: mappedTag) }

        let query = try Keystore.Query.createQueryForKeyGeneration(
            key: key,
            tag: mappedTag,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup
        )

        return try Keystore.Operation.generatePrivateKey(using: query)
    }

    func keyFrom(_ keyType: Keystore.KeyTypeParseMode, storingWithTag tag: String? = nil) throws -> SecKey {
        let key = try Keystore.keyFrom(keyType)
        guard let tag, keyType.isPrivateKey else { return key }

        let mappedTag = map(tag: tag)
        deleteKey(mappedTag: mappedTag)

        let query = try Keystore.Query.createQueryForKeySaving(
            tag: mappedTag,
            key: keyType,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup
        )
        try Keystore.Operation.storeKey(using: query, with: performer)

        return key
    }

    func loadKey(for tag: String) throws -> SecKey {
        try loadPrivateKey(for: tag, context: context, promptMessage: promptMessage)
    }
}

extension Keystore.Vault where B == Keystore.Standard {
    convenience init(
        storeId: String,
        protection: Keychain.Protection,
        accessControl: Keystore.AccessControl,
        accessGroup: String?,
        promptMessage: String?,
        reuseContext: Keychain.ReuseContextMode,
        performer: any KeychainPerforming,
        contextFactory: @escaping @Sendable () -> any LAContextProviding,
        clock: any Clock<Duration>
    ) {
        self.init(
            storeId: storeId,
            protection: protection,
            accessControlFlags: accessControl.flags,
            policy: accessControl.policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContext,
            performer: performer,
            contextFactory: contextFactory,
            clock: clock
        )
    }
}
