//
//  KeychainEncryptedStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation
import LocalAuthentication

public final class KeychainEncryptedStorage: KeychainStorage {
    
    private static let defaultStoreId = "default.encrypted.storage"
    public static let `default` = KeychainEncryptedStorage(storeId: defaultStoreId)
    
    public init(storeId: String, protection: Keychain.Protection = .whenThisDevicePasscodeSet){
        super.init(
            storeId: storeId,
            protection: protection,
            itemClass: kSecClassGenericPassword
        )
        self.promptMessage = promptMessage
    }
}
