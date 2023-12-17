//
//  UserPreferences.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import Foundation

open class UserPreferences: Storage {
    public enum Error: Swift.Error{
        case itemNotFound
        case encodeFailure
        case decodeFailure
        case writingFailure
        case unexpectedError
        case invalidStoreId
    }
    
    public static let `default` = UserPreferences()
    
    private let store: UserDefaults
    private let storeId: String?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(storeId: String? = nil) throws {
        guard let store = UserDefaults(suiteName: storeId) else {
            throw Error.invalidStoreId
        }
        self.storeId = storeId
        self.store = store
    }
    
    init() {
        self.store = .standard
        self.storeId = nil
    }
}

public extension UserPreferences {
    public func save(_ data: Data, withTag tag: String) throws {
        store.set(data, forKey: tag)
    }
    
    public func save<T>(_ object: T, withTag tag: String) throws where T : Encodable {
        let data = try? encoder.encode(object)
        let json = try data.or(throw: Error.encodeFailure)
        store.set(json, forKey: tag)
    }
}

public extension UserPreferences {
    public func loadData(withTag tag: String) throws -> Data {
        try store.data(forKey: tag)
            .or(throw: Error.itemNotFound)
    }
    
    public func loadObject<T>(withTag tag: String) throws -> T where T : Decodable {
        let json = try loadData(withTag: tag)
        let object = try? decoder.decode(T.self, from: json)
        return try object.or(throw: Error.decodeFailure)
    }
}

public extension UserPreferences {
    @discardableResult
    public func deleteItem(withTag tag: String) -> Bool {
        let notExists = store.object(forKey: tag) == nil
        if notExists { return false }
        
        store.set(nil, forKey: tag)
        return true
    }
    
    @discardableResult
    public func clear() -> Bool {
        let keys = store.dictionaryRepresentation().keys
        let keyCount = keys.count
        
        keys.forEach{ store.set(nil, forKey: $0) }
        
        return keyCount != store.dictionaryRepresentation().keys.count
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
