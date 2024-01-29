//
//  KeychainOperation.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import Foundation

enum KeychainOperation{
    
    static func addItem(using query: CFDictionary) throws{
        let status = SecItemAdd(query, nil)
        
        if let err = KeychainStorage.Error(from: status){
            throw err
        }
    }
    
    static func loadItem(using query: CFDictionary) throws -> Data{
        var ref: AnyObject?
        let status = SecItemCopyMatching(query, &ref)
        
        if let err = KeychainStorage.Error(from: status){
            throw err
        }
        
        guard let data = ref as? Data else{
            throw KeychainStorage.Error.itemNotFound
        }
        
        return data
    }
    
    static func loadAttributedItems(using query: CFDictionary) throws -> [[String: Any]] {
        var ref: AnyObject?
        let status = SecItemCopyMatching(query, &ref)
        
        if let err = KeychainStorage.Error(from: status){
            throw err
        }
        
        guard let items = ref as? [[String: Any]] else{
            throw KeychainStorage.Error.itemNotFound
        }
        
        return items
    }
    
    static func deleteItem(using query: CFDictionary) -> Bool{
        let status = SecItemDelete(query)
        
        if KeychainStorage.Error(from: status) != nil{
            return false
        }
        
        return true
    }
}
