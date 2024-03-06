//
//  UserPreferences.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import Foundation

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

extension UserDefaults: Storage {
    public enum StorageError: Swift.Error{
        case itemNotFound
        case encodeFailure
        case decodeFailure
        case writingFailure
        case unexpectedError
        case invalidStoreId
    }
}

public extension UserDefaults {
    func save(_ data: Data, withTag tag: String) throws {
        set(data, forKey: tag)
    }
    
    func save<T>(_ object: T, withTag tag: String) throws where T : Encodable {
        let data = try? encoder.encode(object)
        let json = try data.or(throw: StorageError.encodeFailure)
        set(json, forKey: tag)
    }
}

public extension UserDefaults {
    func loadData(withTag tag: String) throws -> Data {
        try data(forKey: tag)
            .or(throw: StorageError.itemNotFound)
    }
    
    func loadObject<T>(withTag tag: String) throws -> T where T : Decodable {
        let json = try loadData(withTag: tag)
        let object = try? decoder.decode(T.self, from: json)
        return try object.or(throw: StorageError.decodeFailure)
    }
}

public extension UserDefaults {
    @discardableResult
    func deleteItem(withTag tag: String) -> Bool {
        let notExists = object(forKey: tag) == nil
        if notExists { return false }
        
        set(nil, forKey: tag)
        return true
    }
    
    @discardableResult
    func clear() -> Bool {
        let keys = dictionaryRepresentation().keys
        let keyCount = keys.count
        
        keys.forEach{ set(nil, forKey: $0) }
        
        return keyCount != dictionaryRepresentation().keys.count
    }
}

private extension Optional {
    func or(throw error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        return wrapped
    }
}
