//
//  KeychainStorage+Error.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import Foundation

public extension KeychainStorage {
    enum Error: Swift.Error{
        case passcodeDisabled
        case biometryDisabled
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
            case errSecInteractionNotAllowed: self = .passcodeDisabled
            case errSecDecode: self = .decodeFailure
            case errSecAuthFailed: self = .authenticationFailure
            default: self = .unexpectedFailure
            }
        }
    }
}
