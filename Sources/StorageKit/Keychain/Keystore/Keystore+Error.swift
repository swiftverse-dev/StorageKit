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
