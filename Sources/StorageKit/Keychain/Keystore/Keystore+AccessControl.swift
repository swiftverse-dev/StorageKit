//
//  Keystore+AccessControl.swift
//  StorageKit
//

import LocalAuthentication

public extension Keystore {
    /// Who must authenticate before the private key can be used.
    /// The `LAPolicy` comes from the case, so flags and policy cannot disagree.
    enum AccessControl: Sendable {
        case none
        case passcode
        case passcodeOrAnyBiometry
        case currentBiometry
        case anyBiometry
    }
}

extension Keystore.AccessControl {
    var flags: SecAccessControlCreateFlags {
        switch self {
        case .none: return []
        case .passcode: return .devicePasscode
        case .passcodeOrAnyBiometry: return .userPresence
        case .currentBiometry: return .biometryCurrentSet
        case .anyBiometry: return .biometryAny
        }
    }

    var policy: LAPolicy? {
        switch self {
        case .none: return nil
        case .passcode, .passcodeOrAnyBiometry: return .deviceOwnerAuthentication
        case .currentBiometry, .anyBiometry: return .deviceOwnerAuthenticationWithBiometrics
        }
    }
}

public extension Keystore {
    /// The protections the Secure Enclave accepts. They all keep the key on this device.
    enum SecureEnclaveProtection: Sendable {
        case whenThisDevicePasscodeSet
        case whenThisDeviceUnlocked
        case afterThisDeviceFirstUnlock
    }
}

extension Keystore.SecureEnclaveProtection {
    var protection: Keychain.Protection {
        switch self {
        case .whenThisDevicePasscodeSet: return .whenThisDevicePasscodeSet
        case .whenThisDeviceUnlocked: return .whenThisDeviceUnlocked
        case .afterThisDeviceFirstUnlock: return .afterThisDeviceFirstUnlock
        }
    }
}
