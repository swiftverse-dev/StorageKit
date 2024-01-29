//
//  KeychainStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import Foundation
import LocalAuthentication

open class KeychainStorage: Storage{
    public typealias AccessControl = SecAccessControlCreateFlags
    
    public let storeId: String
    public let protection: KeychainStorage.Protection
    public let accessControl: AccessControl
    public let policy: LAPolicy?
    public var promptMessage: String?
    var reuseContext = ReuseContextMode.never
    
    private let itemClass: CFString
    private var _context: LAContext?
    private var context: LAContext {
        switch reuseContext {
        case .always:
            let context = _context ?? LAContext()
            _context = context
            return context
            
        case .never: return LAContext()
            
        case .forInterval(let timeInterval):
            if let _context { return _context }
            
            let newContext = LAContext()
            _context = newContext
            newContext.reuse(for: timeInterval) { [weak self] _ in
                self?._context = nil
            }
            return newContext
        }
    }
    
    public init(
        storeId: String,
        protection: KeychainStorage.Protection,
        accessControl: AccessControl = [],
        policy: LAPolicy? = nil,
        itemClass: CFString = kSecClassGenericPassword
    ) {
        self.storeId = storeId
        self.protection = protection
        self.accessControl = accessControl
        self.policy = policy
        self.itemClass = itemClass
    }
}

// MARK: Save Operations
extension KeychainStorage{
    public func save(_ data: Data, withTag tag: String) throws{
        deleteItem(withTag: tag)
        
        let tag = map(tag: tag)
        
        let query = try CFDictionary.createQueryForDataStore(
            data,
            tag: tag,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy
        )
        
        try KeychainOperation.addItem(using: query)
    }
    
    public func save<T: Encodable>(_ object: T, withTag tag: String) throws{
        guard let encodedObject = try? JSONEncoder().encode(object) else{
            throw KeychainStorage.Error.encodeFailure
        }
        
        try save(encodedObject, withTag: tag)
    }
}

// MARK: Load Operations
extension KeychainStorage{
    public func loadData(withTag tag: String) throws -> Data{
        let tag = map(tag: tag)
        
        let query = try CFDictionary.createQueryForDataRetrieve(
            tag: tag,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            promptMessage: promptMessage
        )
        
        return try KeychainOperation.loadItem(using: query)
    }
    
    public func loadObject<T: Decodable>(withTag tag: String) throws -> T{
        let retrievedData = try loadData(withTag: tag)
        guard let obj = try? JSONDecoder().decode(T.self, from: retrievedData) else {
            throw KeychainStorage.Error.decodeFailure
        }
        
        return obj
    }
}

// MARK: Delete Operations
extension KeychainStorage{
    @discardableResult
    public func deleteItem(withTag tag: String) -> Bool{
        let tag = map(tag: tag)
        return deleteItem(withNoPrefixTag: tag)
    }
    
    private func deleteItem(withNoPrefixTag tag: String) -> Bool {
        let query = CFDictionary.createQueryForDataDeletion(tag: tag, itemClass: itemClass)
        
        return KeychainOperation.deleteItem(using: query)
    }
    
    @discardableResult
    public func clear() -> Bool {
        let optItemsQuery = try? CFDictionary.createQueryForDataRetrieve(
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
            let items = try? KeychainOperation.loadAttributedItems(using: getItemsQuery) else { return false }
        
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

private extension KeychainStorage{
    func map(tag: String) -> String{
        "\(storeId).\(tag)"
    }
}
