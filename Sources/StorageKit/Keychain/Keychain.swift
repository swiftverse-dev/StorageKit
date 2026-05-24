//
//  Keychain.swift
//  StorageKit
//

import Foundation
import LocalAuthentication

open class Keychain{
    public typealias AccessControl = SecAccessControlCreateFlags

    public let storeId: String
    public let protection: Keychain.Protection
    public let accessControl: AccessControl
    public let accessGroup: String?
    public let policy: LAPolicy?
    public var promptMessage: String?
    public var reuseContext = ReuseContextMode.never

    public let itemClass: CFString

    // Internal seams. Defaults wire real Security/LocalAuthentication.
    internal let performer: KeychainPerforming
    internal let contextFactory: () -> LAContextProviding

    private var _context: LAContextProviding?
    internal var context: LAContextProviding {
        switch reuseContext {
        case .always:
            let context = _context ?? contextFactory()
            _context = context
            return context

        case .never: return contextFactory()

        case .forInterval(let timeInterval):
            if let _context { return _context }

            let newContext = contextFactory()
            _context = newContext
            (newContext as? LAContext)?.reuse(for: timeInterval) { [weak self] _ in
                self?._context = nil
            }
            return newContext
        }
    }

    public init(
        storeId: String,
        protection: Keychain.Protection,
        accessControl: AccessControl = [],
        policy: LAPolicy? = nil,
        itemClass: CFString = kSecClassGenericPassword,
        accessGroup: String? = nil
    ) {
        self.storeId = storeId
        self.protection = protection
        self.accessControl = accessControl
        self.policy = policy
        self.itemClass = itemClass
        self.accessGroup = accessGroup
        self.performer = SecItemPerformer()
        self.contextFactory = { LAContext() }
    }

    internal init(
        storeId: String,
        protection: Keychain.Protection,
        accessControl: AccessControl,
        policy: LAPolicy?,
        itemClass: CFString,
        accessGroup: String?,
        performer: KeychainPerforming,
        contextFactory: @escaping () -> LAContextProviding
    ) {
        self.storeId = storeId
        self.protection = protection
        self.accessControl = accessControl
        self.policy = policy
        self.itemClass = itemClass
        self.accessGroup = accessGroup
        self.performer = performer
        self.contextFactory = contextFactory
    }
}
