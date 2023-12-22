//
//  Storage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import Foundation

public typealias Storage = StorageSaver & StorageLoader & StorageRemover

public protocol StorageSaver{
    func save(_ data: Data, withTag tag: String) throws
    func save<T: Encodable>(_ object: T, withTag tag: String) throws
}

public protocol StorageLoader {
    func loadData(withTag tag: String) throws -> Data
    func loadObject<T: Decodable>(withTag tag: String) throws -> T
}

public protocol StorageRemover {
    @discardableResult
    func deleteItem(withTag tag: String) -> Bool
    @discardableResult
    func clear() -> Bool
}
