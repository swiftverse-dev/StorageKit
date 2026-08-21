//
//  ContextStoreTests.swift
//  StorageKitTests
//

import Foundation
import Testing
import Clocks
@testable import StorageKit

final class ContextStoreTests: LeakTrackingTestCase {

    @Test func `never mode builds a fresh context on every call`() {
        let count = Counter()
        let sut = ContextStore(
            mode: .never,
            factory: { count.increment(); return StubLAContext() },
            clock: TestClock()
        )
        trackForMemoryLeaks(sut)

        let a = sut.context()
        let b = sut.context()

        #expect(count.value == 2)
        #expect(a !== b)
    }

    @Test func `always mode returns the same cached context`() {
        let count = Counter()
        let sut = ContextStore(
            mode: .always,
            factory: { count.increment(); return StubLAContext() },
            clock: TestClock()
        )
        trackForMemoryLeaks(sut)

        let a = sut.context()
        let b = sut.context()

        #expect(count.value == 1)
        #expect(a === b)
    }

    @Test func `forInterval mode reuses the context within the interval`() {
        let count = Counter()
        let sut = ContextStore(
            mode: .forInterval(60),
            factory: { count.increment(); return StubLAContext() },
            clock: TestClock()
        )
        trackForMemoryLeaks(sut)

        let a = sut.context()
        let b = sut.context()

        #expect(count.value == 1)
        #expect(a === b)
    }

    @Test func `forInterval mode invalidates and rebuilds after the interval`() async {
        let clock = TestClock()
        let count = Counter()
        let sut = ContextStore(
            mode: .forInterval(60),
            factory: { count.increment(); return StubLAContext() },
            clock: clock
        )
        trackForMemoryLeaks(sut)

        let first = sut.context()
        #expect(count.value == 1)

        await Task.yield()                  // let the internal expiry task reach Task.sleep
        await clock.advance(by: .seconds(60))
        await Task.yield()                  // let the expiry task run its (synchronous) continuation

        let second = sut.context()
        #expect(count.value == 2, "a fresh context must be built after expiry")
        #expect(first !== second)
        #expect((first as? StubLAContext)?.invalidated == true,
                "the expired context must be invalidated")
    }
}
