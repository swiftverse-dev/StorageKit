//
//  Keychain+Query.swift.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import LocalAuthentication

extension Keychain {
    enum Query {}
}

extension Keychain.Query {
    static func createQueryForDataStore(
        _ data: Data,
        tag: String,
        service: String,
        itemClass: CFString,
        context: LAContextProviding,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?,
        accessGroup: String? = nil
    ) throws -> CFDictionary{
        var query: [String: Any] = [
            kSecClass as String                     : itemClass,
            kSecAttrService as String               : service,
            kSecAttrAccount as String               : tag,
            kSecValueData as String                 : data
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
    
    static func createQueryForDataRetrieve(
        tag: String? = nil,
        service: String,
        matchLimit: CFString = kSecMatchLimitOne,
        itemClass: CFString,
        context: LAContextProviding,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?,
        accessGroup: String? = nil,
        returnAttributes: Bool = false,
        promptMessage: String? = nil
    ) throws -> CFDictionary{
        var query = [
            kSecClass as String                     : itemClass,
            kSecReturnData as String                : true,
            kSecMatchLimit as String                : matchLimit,
            kSecReturnAttributes as String          : returnAttributes,
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
            // macOS replacement for the deprecated `kSecUseOperationPrompt`:
            // pass the prompt via `LAContext.localizedReason`. The LAContext
            // itself is written into `kSecUseAuthenticationContext` later by
            // `addAccessControl`.
            context.localizedReason = promptMessage
        }
        #endif
                
        query[kSecAttrService as String] = service
        if let tag {
            query[kSecAttrAccount as String] = tag
        }

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
    
    static func createQueryForDataDeletion(
        tag: String?,
        service: String,
        itemClass: CFString,
        accessGroup: String? = nil
    ) -> CFDictionary{
        var query: [String: Any] = [
            kSecClass as String                     : itemClass,
            kSecAttrService as String               : service,
        ]
        if let tag {
            query[kSecAttrAccount as String] = tag
        }
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query as CFDictionary
    }
}


extension Keychain.Query{
 
    static func addAccessControl(
        to query: inout [String: Any],
        context: LAContextProviding,
        protection: Keychain.Protection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?
    ) throws{
        let access = SecAccessControlCreateWithFlags(
            nil,
            protection.type,
            accessControlFlags,
            nil
        )
        
        guard context.canEvaluatePolicy(policy) else {
            throw policy == .deviceOwnerAuthentication ? Keychain.Error.passcodeDisabled : .biometryDisabled
        }
        
        query[kSecUseAuthenticationContext as String] = context
        query[kSecAttrAccessControl as String] = access
    }
}

private extension LAContextProviding {
    func canEvaluatePolicy(_ policy: LAPolicy?) -> Bool {
        guard let policy else { return true }
        return canEvaluatePolicy(policy, error: nil)
    }
}
