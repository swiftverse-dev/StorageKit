//
//  Keychain+Operation.swift
//  StorageKit
//

import Foundation

extension Keychain {
    enum Operation {}
}

extension Keychain.Operation{

    static func addItem(using query: CFDictionary, with performer: KeychainPerforming) throws{
        let status = performer.add(query)

        if let err = Keychain.Error(from: status){
            throw err
        }
    }

    static func loadItem(using query: CFDictionary, with performer: KeychainPerforming) throws -> Data{
        var ref: CFTypeRef?
        let status = performer.copyMatching(query, result: &ref)

        if let err = Keychain.Error(from: status){
            throw err
        }

        guard let data = ref as? Data else{
            throw Keychain.Error.itemNotFound
        }

        return data
    }

    static func loadAttributedItems(using query: CFDictionary, with performer: KeychainPerforming) throws -> [[String: Any]] {
        var ref: CFTypeRef?
        let status = performer.copyMatching(query, result: &ref)

        if let err = Keychain.Error(from: status){
            throw err
        }

        guard let items = ref as? [[String: Any]] else{
            throw Keychain.Error.itemNotFound
        }

        return items
    }

    static func deleteItem(using query: CFDictionary, with performer: KeychainPerforming) -> Bool{
        let status = performer.delete(query)

        if Keychain.Error(from: status) != nil{
            return false
        }

        return true
    }
}
