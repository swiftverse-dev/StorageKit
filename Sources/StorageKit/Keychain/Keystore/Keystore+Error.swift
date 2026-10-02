//
//  Keystore+Error.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation

public extension Keystore {
    enum Error: Swift.Error, Equatable{
        case badKeySizeError
        case keyGenerationError
        case parsingError
        case encryptionError
        case decryptionError
        case signingError
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
    /// Maps the code of a failed SecKey encrypt, decrypt or sign call. Only a
    /// user cancel and a failed authentication keep their keychain meaning.
    /// Every other code becomes `fallback`.
    init(cryptoFailureCode code: Int, fallback: Keystore.Error) {
        switch Keychain.Error(from: OSStatus(truncatingIfNeeded: code)) {
        case .userCancelOperation?: self = .keychainError(.userCancelOperation)
        case .authenticationFailure?: self = .keychainError(.authenticationFailure)
        default: self = fallback
        }
    }
}
