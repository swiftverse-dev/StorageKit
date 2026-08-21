//
//  Counter.swift
//  StorageKitTests
//

import os

/// Thread-safe call counter for use inside `@Sendable` factory closures.
final class Counter: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: 0)

    var value: Int { state.withLock { $0 } }

    func increment() { state.withLock { $0 += 1 } }
}
