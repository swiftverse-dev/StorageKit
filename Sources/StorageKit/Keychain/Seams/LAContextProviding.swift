//
//  LAContextProviding.swift
//  StorageKit
//

import Foundation
import LocalAuthentication

internal protocol LAContextProviding: AnyObject {
    var localizedReason: String { get set }
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
}

extension LAContext: LAContextProviding {}
