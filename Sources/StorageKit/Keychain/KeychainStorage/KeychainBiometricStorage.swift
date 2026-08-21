//
//  KeychainBiometricStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation
import LocalAuthentication

public final class KeychainBiometricStorage: KeychainStorage, @unchecked Sendable {
    public enum AccessControl {
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
    }

    private static let defaultStoreId = "default.biometric.storage"
    public static let `default` = KeychainBiometricStorage(storeId: defaultStoreId)

    public init(
        storeId: String,
        accessControl: AccessControl = .passcodeOrAnyBiometry,
        policy: LAPolicy = .deviceOwnerAuthentication,
        reuseContextMode: Keychain.ReuseContextMode = .never,
        promptMessage: String? = nil,
        accessGroup: String? = nil
    ){
        super.init(
            storeId: storeId,
            protection: .whenThisDevicePasscodeSet,
            accessControl: accessControl.flags,
            policy: policy,
            accessGroup: accessGroup,
            promptMessage: promptMessage,
            reuseContext: reuseContextMode
        )
    }
}
