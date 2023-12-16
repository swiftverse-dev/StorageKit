//
//  EncryptedStorage.swift
//  JiffySdk
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation

public final class EncryptedStorage: KeychainStorage{
    
    private static let defaultStoreId = Bundle(for: EncryptedStorage.self).bundleIdentifier ?? "" + ".encrypted.storage"
    
    public let storeId: String
    public let protected: Bool = false
    
    public init(storeId: String? = nil){
        self.storeId = storeId ?? Self.defaultStoreId
    }
}
