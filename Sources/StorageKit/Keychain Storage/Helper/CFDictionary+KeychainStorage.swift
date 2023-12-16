//
//  CFDictionary+KeychainDataStorage.swift.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import LocalAuthentication

extension CFDictionary{
    static func createQueryForDataStore(
        _ data: Data,
        tag: String,
        itemClass: CFString,
        context: LAContext,
        protection: KeychainStorageProtection,
        accessControlFlags: SecAccessControlCreateFlags,
        policy: LAPolicy?
    ) throws -> CFDictionary{
        var query: [String: Any] = [
            kSecClass as String                     : itemClass,
            kSecAttrAccount as String               : tag,
            kSecValueData as String                 : data
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
    
    static func createQueryForDataRetrieve(
        tag: String? = nil,
        matchLimit: CFString = kSecMatchLimitOne,
        itemClass: CFString,
        returnAttributes: Bool = false,
        promptMessage: String? = nil
    ) -> CFDictionary{
        var query = [
            kSecClass as String                     : itemClass,
            kSecReturnData as String                : true,
            kSecUseOperationPrompt as String        : promptMessage ?? "Please authenticate",
            kSecMatchLimit as String                : matchLimit,
            kSecReturnAttributes as String          : returnAttributes ? kCFBooleanTrue : kCFBooleanFalse,
        ] as [String: Any]
        
        if let tag {
            query[kSecAttrAccount as String] = tag
        }
        
        return query as CFDictionary
    }
    
    static func createQueryForDataDeletion(tag: String, itemClass: CFString) -> CFDictionary{
        [
            kSecClass as String                     : itemClass,
            kSecAttrAccount as String               : tag,
        ] as CFDictionary
    }
}


private extension CFDictionary{
 
    static func addAccessControl(
        to query: inout [String: Any],
        context: LAContext,
        protection: KeychainStorageProtection,
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
            throw policy == .deviceOwnerAuthentication ? KeychainStorageError.passcodeDisabled : .biometryDisabled
        }
        
        query[kSecUseAuthenticationContext as String] = context
        query[kSecAttrAccessControl as String] = access
    }
}

private extension LAContext {
    func canEvaluatePolicy(_ policy: LAPolicy?) -> Bool {
        guard let policy else { return true }
        return canEvaluatePolicy(policy, error: nil)
    }
}
