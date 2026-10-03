//
//  Keystore+Operation.swift
//  StorageKit
//

import Foundation

extension Keystore {
    enum Operation {}
}

extension Keystore.Operation {
    static func generatePrivateKey(using query: CFDictionary, with performer: any KeychainPerforming) throws -> SecKey {
        var error: Unmanaged<CFError>?
        defer { error?.release() }
        let key = performer.createRandomKey(query, error: &error)
        let keystoreError = (error?.takeUnretainedValue())
            .map{
                let status = CFErrorGetCode($0)
                return Keystore.Error(from: Int32(status)) ?? Keystore.Error.keyGenerationError
            } ?? Keystore.Error.keyGenerationError

        return try key.orThrow(keystoreError)
    }

    static func performCrypto(
        failure: Keystore.Error,
        _ body: (UnsafeMutablePointer<Unmanaged<CFError>?>) -> CFData?
    ) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let result = body(&error) else {
            guard let cfError = error?.takeRetainedValue() else { throw failure }
            throw Keystore.Error(
                cryptoFailureDomain: CFErrorGetDomain(cfError) as String,
                code: CFErrorGetCode(cfError),
                fallback: failure
            )
        }
        return result as Data
    }

    static func storeKey(using query: CFDictionary, with performer: any KeychainPerforming) throws {
        let status = performer.add(query)
        try Keystore.Error(from: status).throwIfExist()
    }

    static func loadPrivateKey(using query: CFDictionary, with performer: any KeychainPerforming) throws -> SecKey {
        var item: CFTypeRef?
        let status = performer.copyMatching(query, result: &item)

        try Keystore.Error(from: status).throwIfExist()

        guard let item, CFGetTypeID(item) == SecKeyGetTypeID() else {
            throw Keystore.Error.keychainError(.itemNotFound)
        }
        return item as! SecKey
    }

    static func createKeyFromData(_ data: Data, using query: CFDictionary) throws -> SecKey {
        try SecKeyCreateWithData(data as CFData, query, nil)
            .orThrow(Keystore.Error.parsingError)
    }

    static func extractPublicKey(from privateKey: SecKey) throws -> SecKey {
        try SecKeyCopyPublicKey(privateKey)
            .orThrow(Keystore.Error.parsingError)
    }

    static func deleteItem(using query: CFDictionary, with performer: any KeychainPerforming) -> Bool{
        let status = performer.delete(query)

        if Keychain.Error(from: status) != nil{
            return false
        }

        return true
    }
}
