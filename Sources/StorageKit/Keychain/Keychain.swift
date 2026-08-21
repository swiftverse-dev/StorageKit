//
//  Keychain.swift
//  StorageKit
//

import Foundation
import LocalAuthentication

open class Keychain: @unchecked Sendable {
    public typealias AccessControl = SecAccessControlCreateFlags

    public let storeId: String
    public let protection: Keychain.Protection
    public let accessControl: AccessControl
    public let accessGroup: String?
    public let policy: LAPolicy?
    public let promptMessage: String?
    public let reuseContext: ReuseContextMode

    public let itemClass: CFString

    // Internal seams. Defaults wire real Security/LocalAuthentication.
    internal let performer: KeychainPerforming

    // The only mutable state in the hierarchy, fully encapsulated and lock-guarded.
    // `@unchecked Sendable` is required only because `performer` (an existential)
    // and `itemClass` (a `CFString`) are not statically `Sendable`; all stored
    // state is immutable `let` and the mutable context cache lives behind
    // `ContextStore`'s lock.
    private let contextStore: ContextStore
    internal var context: LAContextProviding { contextStore.context() }

    public init(
        storeId: String,
        protection: Keychain.Protection,
        accessControl: AccessControl = [],
        policy: LAPolicy? = nil,
        itemClass: CFString = kSecClassGenericPassword,
        accessGroup: String? = nil,
        promptMessage: String? = nil,
        reuseContext: ReuseContextMode = .never
    ) {
        self.storeId = storeId
        self.protection = protection
        self.accessControl = accessControl
        self.policy = policy
        self.itemClass = itemClass
        self.accessGroup = accessGroup
        self.promptMessage = promptMessage
        self.reuseContext = reuseContext
        self.performer = SecItemPerformer()
        self.contextStore = ContextStore(
            mode: reuseContext,
            factory: { LAContext() },
            clock: ContinuousClock()
        )
    }

    internal init(
        storeId: String,
        protection: Keychain.Protection,
        accessControl: AccessControl,
        policy: LAPolicy?,
        itemClass: CFString,
        accessGroup: String?,
        promptMessage: String? = nil,
        reuseContext: ReuseContextMode = .never,
        performer: KeychainPerforming,
        contextFactory: @escaping @Sendable () -> LAContextProviding,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.storeId = storeId
        self.protection = protection
        self.accessControl = accessControl
        self.policy = policy
        self.itemClass = itemClass
        self.accessGroup = accessGroup
        self.promptMessage = promptMessage
        self.reuseContext = reuseContext
        self.performer = performer
        self.contextStore = ContextStore(
            mode: reuseContext,
            factory: contextFactory,
            clock: clock
        )
    }
}
