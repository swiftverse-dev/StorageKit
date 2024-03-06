//
//  Keychain+ReuseContextMode.swift
//  StorageKit
//
//  Created by Lorenzo Limoli on 29/01/24.
//

import Foundation

public extension Keychain {
    enum ReuseContextMode {
        case always
        case never
        case forInterval(TimeInterval)
    }
}
