//
//  StubLAContext.swift
//  StorageKitTests
//

import Foundation
import LocalAuthentication
@testable import StorageKit

final class StubLAContext: LAContextProviding {
    var localizedReason: String = ""
    var canEvaluateResult: Bool = true
    var canEvaluateError: NSError?

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let canEvaluateError {
            error?.pointee = canEvaluateError
        }
        return canEvaluateResult
    }
}
