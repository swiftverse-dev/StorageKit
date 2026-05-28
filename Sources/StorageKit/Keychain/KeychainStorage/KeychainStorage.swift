//
//  KeychainStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation
import LocalAuthentication

open class KeychainStorage: Keychain, Storage {

    public init(
        storeId: String,
        protection: Keychain.Protection,
        accessControl: AccessControl = [],
        policy: LAPolicy? = nil,
        accessGroup: String? = nil
    ) {
        super.init(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            policy: policy,
            itemClass: kSecClassGenericPassword,
            accessGroup: accessGroup
        )
    }

    internal init(
        storeId: String,
        protection: Keychain.Protection,
        accessControl: AccessControl,
        policy: LAPolicy?,
        accessGroup: String?,
        performer: KeychainPerforming,
        contextFactory: @escaping () -> LAContextProviding
    ) {
        super.init(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            policy: policy,
            itemClass: kSecClassGenericPassword,
            accessGroup: accessGroup,
            performer: performer,
            contextFactory: contextFactory
        )
    }
}

// MARK: Save Operations
extension KeychainStorage {
    public func save(_ data: Data, withTag tag: String) throws{
        deleteItem(withTag: tag)

        let query = try Keychain.Query.createQueryForDataStore(
            data,
            tag: tag,
            service: storeId,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup
        )

        try Keychain.Operation.addItem(using: query, with: performer)
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
        let query = try Keychain.Query.createQueryForDataRetrieve(
            tag: tag,
            service: storeId,
            itemClass: itemClass,
            context: context,
            protection: protection,
            accessControlFlags: accessControl,
            policy: policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage
        )

        return try Keychain.Operation.loadItem(using: query, with: performer)
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
        let query = Keychain.Query.createQueryForDataDeletion(
            tag: tag,
            service: storeId,
            itemClass: itemClass,
            accessGroup: accessGroup
        )

        return Keychain.Operation.deleteItem(using: query, with: performer)
    }

    @discardableResult
    public func clear() -> Bool {
        let query = Keychain.Query.createQueryForDataDeletion(
            tag: nil,
            service: storeId,
            itemClass: itemClass,
            accessGroup: accessGroup
        )

        return Keychain.Operation.deleteItem(using: query, with: performer)
    }
}
