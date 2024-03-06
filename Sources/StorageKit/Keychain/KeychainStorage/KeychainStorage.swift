//
//  KeychainStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation

open class KeychainStorage: Keychain, Storage {}


// MARK: Save Operations
extension KeychainStorage {
    public func save(_ data: Data, withTag tag: String) throws{
        deleteItem(withTag: tag)
        
        let tag = map(tag: tag)
        
        let query = try Keychain.Query.createQueryForDataStore(
            data,
            tag: tag,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy
        )
        
        try Keychain.Operation.addItem(using: query)
    }
    
    public func save<T: Encodable>(_ object: T, withTag tag: String) throws{
        guard let encodedObject = try? JSONEncoder().encode(object) else{
            throw Keychain.Error.encodeFailure
        }
        
        try save(encodedObject, withTag: tag)
    }
}

// MARK: Load Operations
extension KeychainStorage {
    public func loadData(withTag tag: String) throws -> Data{
        let tag = map(tag: tag)
        
        let query = try Keychain.Query.createQueryForDataRetrieve(
            tag: tag,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            promptMessage: promptMessage
        )
        
        return try Keychain.Operation.loadItem(using: query)
    }
    
    public func loadObject<T: Decodable>(withTag tag: String) throws -> T{
        let retrievedData = try loadData(withTag: tag)
        guard let obj = try? JSONDecoder().decode(T.self, from: retrievedData) else {
            throw Keychain.Error.decodeFailure
        }
        
        return obj
    }
}

// MARK: Delete Operations
extension KeychainStorage {
    @discardableResult
    public func deleteItem(withTag tag: String) -> Bool{
        let tag = map(tag: tag)
        return deleteItem(withNoPrefixTag: tag)
    }
    
    private func deleteItem(withNoPrefixTag tag: String) -> Bool {
        let query = Keychain.Query.createQueryForDataDeletion(tag: tag, itemClass: itemClass)
        
        return Keychain.Operation.deleteItem(using: query)
    }
    
    @discardableResult
    public func clear() -> Bool {
        let optItemsQuery = try? Keychain.Query.createQueryForDataRetrieve(
            matchLimit: kSecMatchLimitAll,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            returnAttributes: true,
            promptMessage: "Please Authenticate to delete items into keychain"
        )
        
        // Search all the items in the keychain
        guard let getItemsQuery = optItemsQuery,
            let items = try? Keychain.Operation.loadAttributedItems(using: getItemsQuery) else { return false }
        
        let deletedItemsSuccess: [Bool] = items
            .compactMap{
                // Filter the items starting with a prefix equal to `storeId` property
                guard let itemTag = $0[kSecAttrAccount as String] as? String,
                          itemTag.starts(with: storeId) else  {
                    return nil
                }
                // Delete the single Item
                return deleteItem(withNoPrefixTag: itemTag)
            }
        
        return deletedItemsSuccess.isEmpty ? false : deletedItemsSuccess.allSatisfy{ $0 }
    }
}

private extension Keychain {
    func map(tag: String) -> String{
        "\(storeId).\(tag)"
    }
}
