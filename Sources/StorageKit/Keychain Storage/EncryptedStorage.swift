//
//  EncryptedStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation

public final class EncryptedStorage: KeychainStorage{
    
    private static let defaultStoreId = "default.encrypted.storage"
    public static let `default` = EncryptedStorage(storeId: defaultStoreId)
    
    public init(storeId: String){
        super.init(storeId: storeId ?? Self.defaultStoreId, protected: false)
    }
}
