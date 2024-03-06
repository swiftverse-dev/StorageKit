//
//  Keystore+KeyType.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation

public extension Keystore {

    struct KeyType {
        let type: CFString
    }
    
    struct KeyTypeGeneration {
        let type: CFString
        let bitSize: Int
    }
    
    struct KeyTypeParseMode {
        let type: CFString
        let isPrivateKey: Bool
        let data: Data
    }
}

private extension CFString {
    static var rsa: CFString { kSecAttrKeyTypeRSA }
    static var ecPrimeRandom: CFString { kSecAttrKeyTypeECSECPrimeRandom }
}

public extension Keystore.KeyType {
    static var rsa: Keystore.KeyType { .init(type: .rsa) }
    static var ecPrimeRandom: Keystore.KeyType { .init(type: .ecPrimeRandom) }
}

public extension Keystore.KeyTypeGeneration {
    static func rsa(bitSize: Int) -> Keystore.KeyTypeGeneration { .init(type: .rsa, bitSize: bitSize) }
    static var rsa: Keystore.KeyTypeGeneration { .rsa(bitSize: 2048) }
    
    static func ecPrimeRandom(bitSize: Int) -> Keystore.KeyTypeGeneration { .init(type: .ecPrimeRandom, bitSize: bitSize) }
    static var ecPrimeRandom: Keystore.KeyTypeGeneration { .ecPrimeRandom(bitSize: 192) }
}

public extension Keystore.KeyTypeParseMode {
    static func `private`(_ keyType: Keystore.KeyType, data: Data) -> Keystore.KeyTypeParseMode { .init(type: keyType.type, isPrivateKey: true, data: data) }
    static func `public`(_ keyType: Keystore.KeyType, data: Data) -> Keystore.KeyTypeParseMode { .init(type: keyType.type, isPrivateKey: false, data: data) }
}

