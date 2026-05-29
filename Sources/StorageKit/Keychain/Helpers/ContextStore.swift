//
//  ContextStore.swift
//  StorageKit
//

import Foundation
import os

/// Owns the cached `LAContextProviding` and its optional expiry task, serialising
/// every access through an `OSAllocatedUnfairLock`. This is the only mutable state
/// in the `Keychain` hierarchy; encapsulating it here is what lets `Keychain` be
/// `Sendable`.
///
/// Invariant: `State` is only ever read or written inside `state.withLock`/
/// `withLockUnchecked`. The expiry task sleeps on the injected `clock`, so tests
/// can drive expiry deterministically with a `TestClock`.
final class ContextStore: Sendable {

    private struct State {
        var context: LAContextProviding?
        var expiryTask: Task<Void, Never>?
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let mode: Keychain.ReuseContextMode
    private let factory: @Sendable () -> LAContextProviding
    private let clock: any Clock<Duration>

    init(
        mode: Keychain.ReuseContextMode,
        factory: @escaping @Sendable () -> LAContextProviding,
        clock: any Clock<Duration>
    ) {
        self.mode = mode
        self.factory = factory
        self.clock = clock
    }

    /// Returns a context per the reuse mode. Synchronous and lock-backed.
    /// `factory()` is invoked outside the lock; only the cheap cache check/store
    /// (and expiry-task enqueue) happen under it.
    ///
    /// Note: for `.always`/`.forInterval`, the returned context is shared and may
    /// be invalidated by a concurrent TTL expiry shortly after it is returned;
    /// callers must be prepared to handle an invalidated `LAContext`.
    func context() -> LAContextProviding {
        switch mode {
        case .never:
            return factory()

        case .always:
            if let existing = state.withLockUnchecked({ $0.context }) { return existing }
            let new = factory()
            return state.withLockUnchecked { state in
                if let existing = state.context { return existing } // lost the race
                state.context = new
                return new
            }

        case .forInterval(let interval):
            if let existing = state.withLockUnchecked({ $0.context }) { return existing }
            let new = factory()
            return state.withLockUnchecked { state in
                if let existing = state.context { return existing } // lost the race
                state.context = new
                state.expiryTask = self.makeExpiryTask(after: interval)
                return new
            }
        }
    }

    private func makeExpiryTask(after interval: TimeInterval) -> Task<Void, Never> {
        // `clock` captured by value (and `self` weakly) so the task never extends
        // the store's lifetime.
        Task { [weak self, clock] in
            try? await Task.sleep(for: .seconds(interval), clock: clock)
            self?.expire()
        }
    }

    private func expire() {
        state.withLock { state in
            state.context?.invalidate()
            state.context = nil
            state.expiryTask = nil
        }
    }
}
