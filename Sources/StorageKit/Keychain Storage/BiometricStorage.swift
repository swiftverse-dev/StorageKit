//
//  BiometricStorage.swift
//  JiffySdk
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation

public final class BiometricStorage: KeychainStorage{
    
    private static let defaultStoreId = Bundle(for: EncryptedStorage.self).bundleIdentifier ?? "" + ".biometric.storage"
    
    public let storeId: String
    public let protected: Bool = true
    public let promptMessage: String?
    
    public init(storeId: String? = nil, promptMessage: String? = nil){
        self.storeId = storeId ?? Self.defaultStoreId
        self.promptMessage = promptMessage
    }
}
