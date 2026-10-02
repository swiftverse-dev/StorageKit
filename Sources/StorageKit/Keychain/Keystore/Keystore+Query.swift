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
        context: any LAContextProviding,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?,
        accessGroup: String? = nil
    ) throws -> CFDictionary{
        var query: [String: Any] = [
            kSecAttrKeyType as String               : key.type,
            kSecAttrKeySizeInBits as String         : key.bitSize,
            kSecUseAuthenticationContext as String  : context
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Apple reads the access control of a generated key from the private
        // key attributes, not from the top level of the query.
        var privateKeyAttrs: [String: Any] = [:]
        privateKeyAttrs[kSecAttrAccessControl as String] = try Keychain.Query.makeAccessControl(
            context: context,
            protection: protection,
            accessControlFlags: accessControlFlags,
            policy: policy
        )
        if let tag {
            privateKeyAttrs[kSecAttrIsPermanent as String] = true
            privateKeyAttrs[kSecAttrApplicationTag as String] = tag
        }
        query[kSecPrivateKeyAttrs as String] = privateKeyAttrs

        return query as CFDictionary
    }
    
    static func createQueryForKeySaving(
        tag: String,
        key: Keystore.KeyTypeParseMode,
        itemClass: CFString,
        context: any LAContextProviding,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?,
        accessGroup: String? = nil
    ) throws -> CFDictionary{
        var query: [String: Any] = [
            kSecAttrKeyType as String               : key.type,
            kSecClass as String                     : itemClass,
            kSecAttrKeyClass as String              : kSecAttrKeyClassPrivate,
            kSecValueData as String                 : key.data as CFData,
            kSecReturnPersistentRef as String       : true,
            kSecAttrApplicationTag as String        : tag
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        try addAccessControl(
            to: &query,
            context: context,
            protection: protection,
            accessControlFlags: accessControlFlags,
            policy: policy
        )
        
        return query as CFDictionary
    }
    
    static func createQueryForKeyParsing(_ keyType: Keystore.KeyTypeParseMode, accessGroup: String? = nil) -> CFDictionary{
        var query: [String: Any] = [
            kSecAttrKeyType as String               : keyType.type,
            kSecAttrKeyClass as String              : keyType.isPrivateKey ? kSecAttrKeyClassPrivate : kSecAttrKeyClassPublic
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query as CFDictionary
    }
    
    static func createQueryForKeyRetrieve(
        _ key: Keystore.KeyType,
        tag: String,
        matchLimit: CFString = kSecMatchLimitOne,
        itemClass: CFString,
        context: any LAContextProviding,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?,
        accessGroup: String? = nil,
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
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif

        #if os(iOS)
        if let promptMessage {
            query[kSecUseOperationPrompt as String] = promptMessage
        }
        #else
        if let promptMessage {
            context.localizedReason = promptMessage
        }
        #endif

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

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
        itemClass: CFString,
        accessGroup: String? = nil
    ) -> CFDictionary{
        var query: [String: Any] = [
            kSecClass as String                     : itemClass,
            kSecAttrApplicationTag as String        : tag,
            kSecAttrKeyType as String               : key.type,
            kSecAttrKeyClass as String              : kSecAttrKeyClassPrivate
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query as CFDictionary
    }

}

private extension Keystore.Query {

    static func addAccessControl(
        to query: inout [String: Any],
        context: any LAContextProviding,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?
    ) throws{
        try Keychain.Query.addAccessControl(to: &query, context: context, protection: protection, accessControlFlags: accessControlFlags, policy: policy)
    }
}

