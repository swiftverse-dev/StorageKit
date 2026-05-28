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
}
