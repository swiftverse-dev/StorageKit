//
//  KeychainEncryptedStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation
import LocalAuthentication

public final class KeychainEncryptedStorage: KeychainDataStorage{
    
    private static let defaultStoreId = "default.encrypted.storage"
    public static let `default` = KeychainEncryptedStorage(storeId: defaultStoreId)
    
    public init(storeId: String, policy: LAPolicy? = .deviceOwnerAuthentication){
        super.init(
            storeId: storeId,
            protection: .whenThisDevicePasscodeSet,
            policy: policy,
            itemClass: kSecClassGenericPassword
        )
        self.promptMessage = promptMessage
    }
}
