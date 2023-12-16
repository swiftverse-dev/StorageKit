//
//  KeychainStorage.swift
//  JiffySdk
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import Foundation

public enum KeychainStorageError: Swift.Error{
    case passcodeDisabled
    case itemNotFound
    case userCancelOperation
    case storeNotAvailable
    case decodeFailure
    case encodeFailure
    case authenticationFailure
    case unexpectedFailure
    
    public init?(from status: OSStatus){
        switch status {
        case noErr, errSecSuccess: return nil
        case errSecUserCanceled: self = .userCancelOperation
        case errSecNotAvailable: self = .storeNotAvailable
        case errSecItemNotFound: self = .itemNotFound
        case errSecInteractionNotAllowed: self = .passcodeDisabled
        case errSecDecode: self = .decodeFailure
        case errSecAuthFailed: self = .authenticationFailure
        default: self = .unexpectedFailure
        }
    }
}

public protocol KeychainStorage: Storage{
    var storeId: String { get }
    var protected: Bool { get }
    var promptMessage: String? { get }
}

public extension KeychainStorage{
    var promptMessage: String?{ nil }
}

// MARK: Save Operations
extension KeychainStorage{
    public func save(_ data: Data, withTag tag: String) throws{
        deleteItem(withTag: tag)
        
        let tag = map(tag: tag)
        
        let query = try CFDictionary.createQueryForDataStore(data, tag: tag, protected: protected)
        
        try KeychainOperation.addItem(using: query)
    }
    
    public func save<T: Encodable>(_ object: T, withTag tag: String) throws{
        guard let encodedObject = try? JSONEncoder().encode(object) else{
            throw KeychainStorageError.encodeFailure
        }
        
        try save(encodedObject, withTag: tag)
    }
}

// MARK: Load Operations
extension KeychainStorage{
    public func loadData(withTag tag: String) throws -> Data{
        let tag = map(tag: tag)
        
        let query = CFDictionary.createQueryForDataRetrieve(tag: tag, promptMessage: promptMessage)
        
        return try KeychainOperation.loadItem(using: query)
    }
    
    public func loadObject<T: Decodable>(withTag tag: String) throws -> T{
        let retrievedData = try loadData(withTag: tag)
        guard let obj = try? JSONDecoder().decode(T.self, from: retrievedData) else {
            throw KeychainStorageError.decodeFailure
        }
        
        return obj
    }
}

// MARK: Delete Operations
extension KeychainStorage{
    @discardableResult
    public func deleteItem(withTag tag: String) -> Bool{
        let tag = map(tag: tag)
        
        let query = CFDictionary.createQueryForDataDeletion(tag: tag)
        
        return KeychainOperation.deleteItem(using: query)
    }
}

private extension KeychainStorage{
    func map(tag: String) -> String{
        "\(storeId).\(tag)"
    }
}
