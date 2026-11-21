//
//  KeychainBiometricStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation
import LocalAuthentication

public final class KeychainBiometricStorage: KeychainStorage, @unchecked Sendable {
    public enum AccessControl: Sendable {
        case passcode
        case passcodeOrAnyBiometry
        case currentBiometry
        case anyBiometry

        var flags: SecAccessControlCreateFlags {
            switch self {
            case .passcode: return .devicePasscode
            case .passcodeOrAnyBiometry: return .userPresence
            case .currentBiometry: return .biometryCurrentSet
            case .anyBiometry: return .biometryAny
            }
        }

        /// The policy the access control actually requires: biometrics only for
        /// the biometric cases, device owner authentication otherwise.
        var policy: LAPolicy {
            switch self {
            case .passcode, .passcodeOrAnyBiometry: return .deviceOwnerAuthentication
            case .currentBiometry, .anyBiometry: return .deviceOwnerAuthenticationWithBiometrics
            }
        }
    }

    private static let defaultStoreId = "default.biometric.storage"
    public static let `default` = KeychainBiometricStorage(storeId: defaultStoreId)

    /// - Parameter policy: The policy pre-checked before each keychain access.
    ///   `nil` (the default) derives it from `accessControl`, so a biometric
    ///   access control is not pre-checked against passcode authentication.
    public init(
        storeId: String,
        accessControl: AccessControl = .passcodeOrAnyBiometry,
        policy: LAPolicy? = nil,
        reuseContextMode: Keychain.ReuseContextMode = .never,
        promptMessage: String? = nil,
        accessGroup: String? = nil
    ){
        super.init(
            storeId: storeId,
            protection: .whenThisDevicePasscodeSet,
            accessControl: accessControl.flags,
            policy: policy ?? accessControl.policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContextMode
        )
    }
}
