//
//  Keychain+Error.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import Foundation
import LocalAuthentication

public extension Keychain {
    enum Error: Swift.Error, Equatable {
        /// The device has no passcode set.
        case passcodeDisabled
        /// Biometry is unavailable on this device, or the policy cannot be evaluated.
        case biometryDisabled
        /// Biometry is available but no finger or face is enrolled.
        case biometryNotEnrolled
        /// Biometry is locked after too many failed attempts; the passcode unlocks it.
        case biometryLockout
        /// The keychain cannot show UI or the item is not accessible yet,
        /// typically because the device is locked.
        case interactionNotAllowed
        /// The app lacks the entitlement for the access group.
        case missingEntitlement
        case itemNotFound
        case userCancelOperation
        case storeNotAvailable
        case decodeFailure
        case encodeFailure
        case authenticationFailure
        case unexpectedFailure
        
        public init?(from status: OSStatus){
            switch status {
            case noErr, errSecSuccess: return nil
            case errSecUserCanceled: self = .userCancelOperation
            case errSecNotAvailable: self = .storeNotAvailable
            case errSecItemNotFound: self = .itemNotFound
            case errSecInteractionNotAllowed: self = .interactionNotAllowed
            case errSecMissingEntitlement: self = .missingEntitlement
            case errSecDecode: self = .decodeFailure
            case errSecAuthFailed: self = .authenticationFailure
            default: self = .unexpectedFailure
            }
        }
    }
}

extension Keychain.Error {
    /// Maps a failed `canEvaluatePolicy` to the reason the user can act on.
    init(evaluating policy: LAPolicy, failure: NSError?) {
        switch failure.flatMap({ $0.domain == LAErrorDomain ? LAError.Code(rawValue: $0.code) : nil }) {
        case .passcodeNotSet: self = .passcodeDisabled
        case .biometryNotEnrolled: self = .biometryNotEnrolled
        case .biometryLockout: self = .biometryLockout
        case .biometryNotAvailable: self = .biometryDisabled
        default: self = policy == .deviceOwnerAuthentication ? .passcodeDisabled : .biometryDisabled
        }
    }
}
