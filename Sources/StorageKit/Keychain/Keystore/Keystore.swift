//
//  Keystore.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation
import LocalAuthentication

public final class Keystore: Keychain {
    private static let defaultStoreId = "default.keystore"
    static let `default` = Keystore(
        storeId: defaultStoreId,
        protection: .whenThisDeviceUnlocked
    )
    
    public init(
        storeId: String,
        protection: Protection,
        accessControl: AccessControl = [],
        policy: LAPolicy? = nil
    ) {
        super.init(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            policy: policy,
            itemClass: kSecClassKey
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
            policy: policy
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
                policy: policy
            )
            
            try Operation.storeKey(using: storeKeyQuery)
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
            promptMessage: promptMessage
        )
        
        return try Operation.loadPrivateKey(using: query)
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
            itemClass: itemClass
        )
        return Operation.deleteItem(using: query)
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
            policy: nil
        )
        
        return try Operation.generatePrivateKey(using: query)
    }
    static func keyFrom(_ keyType: KeyTypeParseMode) throws -> SecKey {
        let keyParsingQuery = Query.createQueryForKeyParsing(keyType)
        return try Operation.createKeyFromData(keyType.data, using: keyParsingQuery)
    }
}

private extension Keystore{
    func map(tag: String) -> String{
        "\(storeId).\(tag)"
    }
}
