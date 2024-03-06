//
//  Keystore+Operation.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation

extension Keystore {
    enum Operation {}
}

extension Keystore.Operation {
    static func generatePrivateKey(using query: CFDictionary) throws -> SecKey {
        var error: Unmanaged<CFError>?
        defer { error?.release() }
        let key = SecKeyCreateRandomKey(query, &error)
        let keystoreError = (error?.takeUnretainedValue())
            .map{
                let status = CFErrorGetCode($0)
                return Keystore.Error(from: Int32(status)) ?? Keystore.Error.keyGenerationError
            } ?? Keystore.Error.keyGenerationError
            
        return try key.orThrow(keystoreError)
    }
    
    static func storeKey(using query: CFDictionary) throws {
        let status = SecItemAdd(query, nil)
        try Keystore.Error(from: status).throwIfExist()
    }
    
    static func loadPrivateKey(using query: CFDictionary) throws -> SecKey {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        
        try Keystore.Error(from: status).throwIfExist()
        
        return (item as! SecKey)
    }
    
    static func createKeyFromData(_ data: Data, using query: CFDictionary) throws -> SecKey {
        try SecKeyCreateWithData(data as CFData, query, nil)
            .orThrow(Keystore.Error.parsingError)
    }
    
    static func extractPublicKey(from privateKey: SecKey) throws -> SecKey {
        try SecKeyCopyPublicKey(privateKey)
            .orThrow(Keystore.Error.parsingError)
    }
    
    static func deleteItem(using query: CFDictionary) -> Bool{
        let status = SecItemDelete(query)
        
        if Keychain.Error(from: status) != nil{
            return false
        }
        
        return true
    }
}
