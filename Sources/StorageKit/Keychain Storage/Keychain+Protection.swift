//
//  Keychain+Protection.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import Foundation

public extension Keychain {
    enum Protection {
        case whenUnlocked
        case afterFirstUnlock
        
        case whenThisDevicePasscodeSet
        case whenThisDeviceUnlocked
        case afterThisDeviceFirstUnlock
        
        var type: CFString{
            switch self {
            case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
            case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
            case .whenThisDevicePasscodeSet: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .whenThisDeviceUnlocked: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterThisDeviceFirstUnlock: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }
}
