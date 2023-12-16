//
//  BiometricStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation

public final class BiometricStorage: KeychainStorage{
    
    private static let defaultStoreId = "default.biometric.storage"
    public static let `default` = BiometricStorage(storeId: defaultStoreId)
    
    public init(storeId: String, promptMessage: String? = nil){
        super.init(
            storeId: storeId ?? Self.defaultStoreId,
            protected: true,
            promptMessage: promptMessage
        )
    }
}
