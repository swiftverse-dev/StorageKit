//
//  KeychainOperation.swift
//  JiffySdk
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import Foundation

enum KeychainOperation{
    
    static func addItem(using query: CFDictionary) throws{
        let status = SecItemAdd(query, nil)
        
        if let err = KeychainStorageError(from: status){
            throw err
        }
    }
    
    static func loadItem(using query: CFDictionary) throws -> Data{
        var ref: AnyObject?
        let status = SecItemCopyMatching(query, &ref)
        
        if let err = KeychainStorageError(from: status){
            throw err
        }
        
        guard let data = ref as? Data else{
            throw KeychainStorageError.itemNotFound
        }
        
        return data
    }
    
    static func loadAttributedItems(using query: CFDictionary) throws -> [[String: Any]] {
        var ref: AnyObject?
        let status = SecItemCopyMatching(query, &ref)
        
        if let err = KeychainStorageError(from: status){
            throw err
        }
        
        guard let items = ref as? [[String: Any]] else{
            throw KeychainStorageError.itemNotFound
        }
        
        return items
    }
    
    static func deleteItem(using query: CFDictionary) -> Bool{
        let status = SecItemDelete(query)
        
        if KeychainStorageError(from: status) != nil{
            return false
        }
        
        return true
    }
}
