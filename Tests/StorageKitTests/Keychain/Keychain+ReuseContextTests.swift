//
//  Keychain+ReuseContextTests.swift
//  StorageKitTests
//

import Foundation
import Testing
@testable import StorageKit

final class KeychainReuseContextTests: LeakTrackingTestCase {

    @Test func `never mode produces a fresh context on every access`() {
        let count = Counter()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            reuseContext: .never,
            contextFactory: { count.increment(); return StubLAContext() }
        )
        trackForMemoryLeaks(sut)

        _ = sut.context
        _ = sut.context
        _ = sut.context

        #expect(count.value == 3)
    }

    @Test func `always mode reuses the same context`() {
        let count = Counter()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            reuseContext: .always,
            contextFactory: { count.increment(); return StubLAContext() }
        )
        trackForMemoryLeaks(sut)

        let first = sut.context
        let second = sut.context
        let third = sut.context

        #expect(count.value == 1)
        #expect(first === second)
        #expect(second === third)
    }

    @Test func `forInterval mode reuses the context during the interval`() {
        let count = Counter()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            reuseContext: .forInterval(60),
            contextFactory: { count.increment(); return StubLAContext() }
        )
        trackForMemoryLeaks(sut)

        let first = sut.context
        let second = sut.context

        #expect(count.value == 1)
        #expect(first === second)
    }
}
