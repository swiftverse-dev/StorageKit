//
//  StubLAContext.swift
//  StorageKitTests
//

import Foundation
import LocalAuthentication
@testable import StorageKit

// Test double, used single-threaded: configured before injection and only read
// on the test thread. `@unchecked` is safe for this usage.
final class StubLAContext: LAContextProviding, @unchecked Sendable {
    var localizedReason: String = ""
    var canEvaluateResult: Bool = true
    var canEvaluateError: NSError?
    private(set) var invalidated = false

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let canEvaluateError {
            error?.pointee = canEvaluateError
        }
        return canEvaluateResult
    }

    func invalidate() { invalidated = true }
}
