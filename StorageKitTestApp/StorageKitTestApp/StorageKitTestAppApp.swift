//
//  StorageKitTestAppApp.swift
//  StorageKitTestApp
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import SwiftUI
import StorageKit

@main
struct StorageKitTestAppApp: App {
    var body: some Scene {
        WindowGroup {
            Button("Authenticate") {
                test()
            }
        }
    }
    
    func test() {
        let storeID = "keychain.store"
        let encryptedStore = EncryptedStorage(storeId: storeID)
        let biometricStore = BiometricStorage(storeId: storeID)
        
        let value = Data("value".utf8)
        
        try! encryptedStore.save(value, withTag: "tag1")
        try! encryptedStore.save(value, withTag: "tag2")
        try! biometricStore.save(value, withTag: "tag3")
        
        encryptedStore.clear()
    }
}
