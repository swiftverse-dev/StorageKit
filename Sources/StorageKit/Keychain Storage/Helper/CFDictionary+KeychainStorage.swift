//
//  CFDictionary+KeychainStorage.swift.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import LocalAuthentication

extension CFDictionary{
    static func createQueryForDataStore(_ data: Data, tag: String, protected: Bool) throws -> CFDictionary{
        var query: [String: Any] = [
            kSecClass as String                     : kSecClassGenericPassword,
            kSecAttrAccount as String               : tag,
            kSecValueData as String                 : data
        ]
        
        if protected{
            try addBiometryProtection(to: &query)
        }else{
            try addAccessControl(to: &query)
        }
        
        return query as CFDictionary
    }
    
    static func createQueryForDataRetrieve(
        tag: String? = nil,
        matchLimit: CFString = kSecMatchLimitOne,
        returnAttributes: Bool = false,
        promptMessage: String? = nil
    ) -> CFDictionary{
        var query = [
            kSecClass as String                     : kSecClassGenericPassword,
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
    
    static func createQueryForDataDeletion(tag: String) -> CFDictionary{
        [
            kSecClass as String                     : kSecClassGenericPassword,
            kSecAttrAccount as String               : tag,
        ] as CFDictionary
    }
}


private extension CFDictionary{
    static func setupAccessibility(protection: CFString, flags: SecAccessControlCreateFlags) -> (context: LAContext, access: SecAccessControl){
        let context = LAContext()
        let access = SecAccessControlCreateWithFlags(
            nil,
            protection,
            flags,
            nil
        )!
        
        return (context, access)
    }
    
    static func addBiometryProtection(to query: inout [String: Any]) throws{
        let (context, access) = Self.setupAccessibility(protection: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, flags: .userPresence)
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else{
            throw KeychainStorageError.passcodeDisabled
        }
        
        query[kSecUseAuthenticationContext as String] = context
        query[kSecAttrAccessControl as String] = access
    }
    
    static func addAccessControl(to query: inout [String: Any]) throws{
        let (context, access) = Self.setupAccessibility(protection: kSecAttrAccessibleWhenUnlocked, flags: [])
        
        query[kSecUseAuthenticationContext as String] = context
        query[kSecAttrAccessControl as String] = access
    }
}
