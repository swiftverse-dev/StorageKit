//
//  ContextStoreTests.swift
//  StorageKitTests
//

import XCTest
import Clocks
@testable import StorageKit

final class ContextStoreTests: XCTestCase {

    func test_never_returnsFreshContextEachCall() {
        let count = Counter()
        let sut = ContextStore(
            mode: .never,
            factory: { count.increment(); return StubLAContext() },
            clock: TestClock()
        )

        let a = sut.context()
        let b = sut.context()

        XCTAssertEqual(count.value, 2)
        XCTAssertFalse(a === b)
    }

    func test_always_returnsSameCachedContext() {
        let count = Counter()
        let sut = ContextStore(
            mode: .always,
            factory: { count.increment(); return StubLAContext() },
            clock: TestClock()
        )

        let a = sut.context()
        let b = sut.context()

        XCTAssertEqual(count.value, 1)
        XCTAssertTrue(a === b)
    }

    func test_forInterval_reusesContextWithinTheInterval() {
        let count = Counter()
        let sut = ContextStore(
            mode: .forInterval(60),
            factory: { count.increment(); return StubLAContext() },
            clock: TestClock()
        )

        let a = sut.context()
        let b = sut.context()

        XCTAssertEqual(count.value, 1)
        XCTAssertTrue(a === b)
    }

    func test_forInterval_invalidatesAndRebuildsAfterTheInterval() async {
        let clock = TestClock()
        let count = Counter()
        let sut = ContextStore(
            mode: .forInterval(60),
            factory: { count.increment(); return StubLAContext() },
            clock: clock
        )

        let first = sut.context()
        XCTAssertEqual(count.value, 1)

        await Task.yield()                  // let the internal expiry task reach Task.sleep
        await clock.advance(by: .seconds(60))
        await Task.yield()                  // let the expiry task run its (synchronous) continuation

        let second = sut.context()
        XCTAssertEqual(count.value, 2, "a fresh context must be built after expiry")
        XCTAssertFalse(first === second)
        XCTAssertTrue((first as? StubLAContext)?.invalidated == true,
                      "the expired context must be invalidated")
    }
}
