//
//  Keystore+Error.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation
import LocalAuthentication

public extension Keystore {
    enum Error: Swift.Error, Equatable{
        case badKeySizeError
        case keyGenerationError
        case parsingError
        case encryptionError
        case decryptionError
        case signingError
        case secureEnclaveUnavailable
        case keychainError(Keychain.Error)
        
        init?(from status: OSStatus){
            switch status {
            case errSecKeySizeNotAllowed, -50: self = .badKeySizeError
            default:
                guard let err = Keychain.Error(from: status) else { return nil }
                self = .keychainError(err)
            }
        }
    }
}

extension Keystore.Error {
    /// Maps a failed SecKey encrypt, decrypt or sign call. Only a cancel and a
    /// failed authentication keep their meaning. Every other error becomes
    /// `fallback`. A Secure Enclave key reports these in the LocalAuthentication
    /// domain, other keys as an OSStatus.
    init(cryptoFailureDomain domain: String, code: Int, fallback: Keystore.Error) {
        switch (domain, code) {
        case (LAErrorDomain, LAError.userCancel.rawValue),
             (LAErrorDomain, LAError.systemCancel.rawValue),
             (LAErrorDomain, LAError.appCancel.rawValue),
             (NSOSStatusErrorDomain, Int(errSecUserCanceled)):
            self = .keychainError(.userCancelOperation)
        case (LAErrorDomain, LAError.authenticationFailed.rawValue),
             (NSOSStatusErrorDomain, Int(errSecAuthFailed)):
            self = .keychainError(.authenticationFailure)
        default:
            self = fallback
        }
    }
}
