//
//  KeychainSUTFactory.swift
//  StorageKitTests
//

import Foundation
import LocalAuthentication
import Clocks
@testable import StorageKit

enum KeychainSUTFactory {

    static func makeKeychainStorage(
        storeId: String = "test.keychain.storage",
        protection: Keychain.Protection = .whenUnlocked,
        accessControl: Keychain.AccessControl = [],
        policy: LAPolicy? = nil,
        performer: any KeychainPerforming,
        accessGroup: String? = nil,
        promptMessage: String? = nil,
        reuseContext: Keychain.ReuseContextMode = .never,
        clock: any Clock<Duration> = TestClock(),
        contextFactory: @escaping @Sendable () -> any LAContextProviding = { StubLAContext() }
    ) -> KeychainStorage {
        KeychainStorage(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            policy: policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContext,
            performer: performer,
            contextFactory: contextFactory,
            clock: clock
        )
    }

    static func makeKeystore(
        storeId: String = "test.keystore",
        protection: Keychain.Protection = .whenUnlocked,
        accessControl: Keychain.AccessControl = [],
        policy: LAPolicy? = nil,
        performer: any KeychainPerforming,
        accessGroup: String? = nil,
        promptMessage: String? = nil,
        reuseContext: Keychain.ReuseContextMode = .never,
        clock: any Clock<Duration> = TestClock(),
        contextFactory: @escaping @Sendable () -> any LAContextProviding = { StubLAContext() }
    ) -> Keystore {
        Keystore(
            storeId: storeId,
            protection: protection,
            accessControl: accessControl,
            policy: policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContext,
            performer: performer,
            contextFactory: contextFactory,
            clock: clock
        )
    }
}
