//
//  Keystore.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation
import LocalAuthentication

/// Namespace for key storage. Create a `Keystore.StandardVault` for software
/// keys. The marker type picks which API the vault exposes.
public enum Keystore {
    public protocol Backing {}
    public enum Standard: Backing {}

    public typealias StandardVault = Vault<Standard>

    public static let defaultStoreId = "default.keystore"
    public static let standard = StandardVault(
        storeId: defaultStoreId,
        protection: .whenThisDeviceUnlocked
    )
}

public extension Keystore {
    static func generate(key: KeyTypeGeneration) throws -> SecKey {
        let query = try Query.createQueryForKeyGeneration(
            key: key,
            tag: nil,
            context: LAContext(),
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil,
            accessGroup: nil
        )

        return try Operation.generatePrivateKey(using: query, with: SecItemPerformer())
    }

    static func keyFrom(_ keyType: KeyTypeParseMode) throws -> SecKey {
        let keyParsingQuery = Query.createQueryForKeyParsing(keyType)
        return try Operation.createKeyFromData(keyType.data, using: keyParsingQuery)
    }

    static func extractPublicKey(from privateKey: SecKey) throws -> SecKey {
        try Operation.extractPublicKey(from: privateKey)
    }
}
