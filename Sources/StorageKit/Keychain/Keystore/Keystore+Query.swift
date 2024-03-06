//
//  Keystore+Query.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation
import LocalAuthentication

extension Keystore {
    enum Query {}
}

extension Keystore.Query {
    
    static func createQueryForKeyGeneration(
        key: Keystore.KeyTypeGeneration,
        tag: String?,
        itemClass: CFString,
        context: LAContext,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?
    ) throws -> CFDictionary{
        var query: [String: Any] = [
            kSecAttrKeyType as String               : key.type,
            kSecAttrKeySizeInBits as String         : key.bitSize
        ]
        
        addPermanentAttributesIfApplicable(to: &query, tag: tag)

        try addAccessControl(
            to: &query,
            context: context,
            protection: protection,
            accessControlFlags: accessControlFlags,
            policy: policy
        )
        
        return query as CFDictionary
    }
    
    static func createQueryForKeySaving(
        tag: String,
        key: Keystore.KeyTypeParseMode,
        itemClass: CFString,
        context: LAContext,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?
    ) throws -> CFDictionary{
        var query: [String: Any] = [
            kSecAttrKeyType as String               : key.type,
            kSecClass as String                     : itemClass,
            kSecAttrKeyClass as String              : kSecAttrKeyClassPrivate,
            kSecValueData as String                 : key.data as CFData,
            kSecReturnPersistentRef as String       : true,
            kSecAttrApplicationTag as String        : tag
        ]
        
        try addAccessControl(
            to: &query,
            context: context,
            protection: protection,
            accessControlFlags: accessControlFlags,
            policy: policy
        )
        
        return query as CFDictionary
    }
    
    static func createQueryForKeyParsing(_ keyType: Keystore.KeyTypeParseMode) -> CFDictionary{
        let query: [String: Any] = [
            kSecAttrKeyType as String               : keyType.type,
            kSecAttrKeyClass as String              : keyType.isPrivateKey ? kSecAttrKeyClassPrivate : kSecAttrKeyClassPublic
        ]
        
        return query as CFDictionary
    }
    
    static func createQueryForKeyRetrieve(
        _ key: Keystore.KeyType,
        tag: String,
        matchLimit: CFString = kSecMatchLimitOne,
        itemClass: CFString,
        context: LAContext,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?,
        returnAttributes: Bool = false,
        promptMessage: String? = nil
    ) throws -> CFDictionary{
        var query = [
            kSecClass as String                     : itemClass,
            kSecReturnRef as String                 : true,
            kSecMatchLimit as String                : matchLimit,
            kSecReturnAttributes as String          : returnAttributes,
            kSecAttrKeyType as String               : key.type,
            kSecAttrApplicationTag as String        : tag
        ] as [String: Any]
        
        #if TARGET_OS_IPHONE
        if let promptMessage {
            query[kSecUseOperationPrompt as String] = promptMessage
        }
        #else
        if let promptMessage {
            query[kSecUseAuthenticationContext as String] = promptMessage
            context.localizedReason = promptMessage
        }
        #endif
        
        try addAccessControl(
            to: &query,
            context: context,
            protection: protection,
            accessControlFlags: accessControlFlags,
            policy: policy
        )
        
        return query as CFDictionary
    }

    static func createQueryForKeyDeletion(
        _ key: Keystore.KeyType,
        tag: String,
        itemClass: CFString
    ) -> CFDictionary{
        [
            kSecClass as String                     : itemClass,
            kSecAttrApplicationTag as String        : tag,
            kSecAttrKeyType as String               : key.type,
            kSecAttrKeyClass as String              : kSecAttrKeyClassPrivate
        ] as CFDictionary
    }

}

private extension Keystore.Query {

    static func addAccessControl(
        to query: inout [String: Any],
        context: LAContext,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?
    ) throws{
        try Keychain.Query.addAccessControl(to: &query, context: context, protection: protection, accessControlFlags: accessControlFlags, policy: policy)
    }
    static func addPermanentAttributesIfApplicable(to query: inout [String: Any], tag: String?){
        guard let tag else { return }
        query[kSecPrivateKeyAttrs as String] = [
            kSecAttrIsPermanent as String       : true,
            kSecAttrApplicationTag as String    : tag
        ]
    }
}

