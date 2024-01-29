//
//  StorageKitTestApp.swift
//  StorageKitTestApp
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import SwiftUI
import StorageKit

@main
struct StorageKitTestApp: App {
    var body: some Scene {
        WindowGroup {
            Button("Authenticate") {
                try! test()
            }
        }
    }
    
    func test() throws {
        let keychain = KeychainBiometricStorage.default
        keychain.reuseContextMode = .forInterval(10)
        
        try keychain.save(Data("ciao".utf8), withTag: "a")
        try keychain.save(Data("ciao".utf8), withTag: "b")
        
        print(try keychain.loadData(withTag: "a"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print(try! keychain.loadData(withTag: "b"))
            keychain.clear()
        }
    }
}
