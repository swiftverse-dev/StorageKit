//
//  KeychainStorage+ReuseContextMode.swift
//
//
//  Created by Lorenzo Limoli on 29/01/24.
//

import Foundation

public extension KeychainStorage {
    enum ReuseContextMode {
        case always
        case never
        case forInterval(TimeInterval)
    }
}
