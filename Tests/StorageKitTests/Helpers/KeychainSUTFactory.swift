//
//  KeychainSUTFactory.swift
//  StorageKitTests
//

import Foundation
import LocalAuthentication
@testable import StorageKit

enum KeychainSUTFactory {

    static func makeKeychainStorage(
        storeId: String = "test.keychain.storage",
        protection: Keychain.Protection = .whenUnlocked,
        accessControl: Keychain.AccessControl = [],
        policy: LAPolicy? = nil,
        performer: KeychainPerforming,
        accessGroup: String? = nil,
        contextFactory: @escaping () -> LAContextProviding = { StubLAContext() }
    ) -> KeychainStorage {
        KeychainStorage(
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

    static func makeKeystore(
        storeId: String = "test.keystore",
        protection: Keychain.Protection = .whenUnlocked,
        accessControl: Keychain.AccessControl = [],
        policy: LAPolicy? = nil,
        performer: KeychainPerforming,
        accessGroup: String? = nil,
        contextFactory: @escaping () -> LAContextProviding = { StubLAContext() }
    ) -> Keystore {
        Keystore(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            policy: policy,
            accessGroup: accessGroup,
            performer: performer,
            contextFactory: contextFactory
        )
    }
}
