//
//  KeychainPerforming.swift
//  StorageKit
//

import Foundation

internal protocol KeychainPerforming {
    func add(_ query: CFDictionary) -> OSStatus
    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func update(_ query: CFDictionary, attributes: CFDictionary) -> OSStatus
    func delete(_ query: CFDictionary) -> OSStatus
    func createRandomKey(_ attributes: CFDictionary, error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey?
}

internal struct SecItemPerformer: KeychainPerforming {
    func add(_ query: CFDictionary) -> OSStatus {
        SecItemAdd(query, nil)
    }

    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemCopyMatching(query, result)
    }

    func update(_ query: CFDictionary, attributes: CFDictionary) -> OSStatus {
        SecItemUpdate(query, attributes)
    }

    func delete(_ query: CFDictionary) -> OSStatus {
        SecItemDelete(query)
    }

    func createRandomKey(_ attributes: CFDictionary, error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey? {
        SecKeyCreateRandomKey(attributes, error)
    }
}
