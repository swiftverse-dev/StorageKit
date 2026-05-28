//
//  KeychainEncryptedStorage.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation

public final class KeychainEncryptedStorage: KeychainStorage {

    private static let defaultStoreId = "default.encrypted.storage"
    public static let `default` = KeychainEncryptedStorage(storeId: defaultStoreId)

    public init(
        storeId: String,
        protection: Keychain.Protection = .whenThisDevicePasscodeSet,
        accessGroup: String? = nil
    ){
        super.init(
            storeId: storeId,
            protection: protection,
            accessGroup: accessGroup
        )
    }
}
