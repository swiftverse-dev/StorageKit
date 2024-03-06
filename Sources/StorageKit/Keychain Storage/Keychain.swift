//
//  Keychain.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import Foundation
import LocalAuthentication

open class Keychain{
    public typealias AccessControl = SecAccessControlCreateFlags
    
    public let storeId: String
    public let protection: Keychain.Protection
    public let accessControl: AccessControl
    public let policy: LAPolicy?
    public var promptMessage: String?
    public var reuseContext = ReuseContextMode.never
    
    public let itemClass: CFString
    private var _context: LAContext?
    public var context: LAContext {
        switch reuseContext {
        case .always:
            let context = _context ?? LAContext()
            _context = context
            return context
            
        case .never: return LAContext()
            
        case .forInterval(let timeInterval):
            if let _context { return _context }
            
            let newContext = LAContext()
            _context = newContext
            newContext.reuse(for: timeInterval) { [weak self] _ in
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
        itemClass: CFString = kSecClassGenericPassword
    ) {
        self.storeId = storeId
        self.protection = protection
        self.accessControl = accessControl
        self.policy = policy
        self.itemClass = itemClass
    }
}
