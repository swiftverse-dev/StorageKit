//
//  Keystore.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation
import LocalAuthentication

public final class Keystore: Keychain, @unchecked Sendable {
    public static let defaultStoreId = "default.keystore"
    public static let `default` = Keystore(
        storeId: defaultStoreId,
        protection: .whenThisDeviceUnlocked
    )
    
    public init(
        storeId: String,
        protection: Protection,
        accessControl: AccessControl = [],
        policy: LAPolicy? = nil,
        accessGroup: String? = nil,
        promptMessage: String? = nil,
        reuseContext: ReuseContextMode = .never
    ) {
        super.init(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            policy: policy,
            itemClass: kSecClassKey,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContext
        )
    }

    internal init(
        storeId: String,
        protection: Protection,
        accessControl: AccessControl,
        policy: LAPolicy?,
        accessGroup: String?,
        promptMessage: String? = nil,
        reuseContext: ReuseContextMode = .never,
        performer: KeychainPerforming,
        contextFactory: @escaping @Sendable () -> LAContextProviding,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        super.init(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
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


// MARK: Key Generation
public extension Keystore {
    func generate(key: KeyTypeGeneration, forTag tag: String? = nil) throws -> SecKey {
        
        let tag = tag.map(map(tag:)) ?? nil
        _ = tag.map(deleteKey(alreadyMappedTag:))
        
        let query = try Query.createQueryForKeyGeneration(
            key: key,
            tag: tag,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup
        )

        return try Operation.generatePrivateKey(using: query)
    }

    func keyFrom(_ keyType: KeyTypeParseMode, storingWithTag tag: String? = nil) throws -> SecKey {
        let key = try Self.keyFrom(keyType)
        let tag = tag.map(map(tag:)) ?? nil
        
        if let tag, keyType.isPrivateKey {
            deleteKey(alreadyMappedTag: tag)
            
            let storeKeyQuery = try Query.createQueryForKeySaving(
                tag: tag,
                key: keyType,
                itemClass: itemClass,
                context: context,
                protection: protection,
                accessControlFlags: accessControl,
                policy: policy,
                accessGroup: accessGroup
            )
            
            try Operation.storeKey(using: storeKeyQuery, with: performer)
        }
        
        return key
    }
    
    func loadKey(for tag: String) throws -> SecKey {
        let tag = map(tag: tag)
        
        let query = try Query.createQueryForKeyRetrieve(
            .rsa,
            tag: tag,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage
        )
        
        return try Operation.loadPrivateKey(using: query, with: performer)
    }
    
    @discardableResult
    func deleteKey(for tag: String) -> Bool {
        let tag = map(tag: tag)
        return deleteKey(alreadyMappedTag: tag)
    }
    
    @discardableResult
    private func deleteKey(alreadyMappedTag: String) -> Bool {
        let query = Query.createQueryForKeyDeletion(
            .rsa,
            tag: alreadyMappedTag,
            itemClass: itemClass,
            accessGroup: accessGroup
        )
        return Operation.deleteItem(using: query, with: performer)
    }
}

public extension Keystore {
    static func generate(key: KeyTypeGeneration) throws -> SecKey {
        let query = try Query.createQueryForKeyGeneration(
            key: key,
            tag: nil,
            itemClass: kSecClassKey,
            context: LAContext(),
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil,
            accessGroup: nil
        )
        
        return try Operation.generatePrivateKey(using: query)
    }
    
    static func keyFrom(_ keyType: KeyTypeParseMode) throws -> SecKey {
        let keyParsingQuery = Query.createQueryForKeyParsing(keyType)
        return try Operation.createKeyFromData(keyType.data, using: keyParsingQuery)
    }
    
    static func extractPublicKey(from privateKey: SecKey) throws -> SecKey {
        try Operation.extractPublicKey(from: privateKey)
    }
}

private extension Keystore{
    func map(tag: String) -> String{
        "\(storeId).\(tag)"
    }
}
