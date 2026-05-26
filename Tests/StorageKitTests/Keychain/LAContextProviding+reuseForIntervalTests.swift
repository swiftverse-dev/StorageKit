//
//  LAContextProviding+reuseForIntervalTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class LAContextProvidingReuseForIntervalTests: XCTestCase {

    func test_reuseForInterval_invalidatesContextWhenTimerFires() {
        let stub = StubLAContext()
        let done = expectation(description: "interval elapsed")

        stub.reuse(for: 0.05) { context in
            XCTAssertTrue(context === stub)
            done.fulfill()
        }

        XCTAssertFalse(stub.invalidated, "must not invalidate before the interval elapses")
        wait(for: [done], timeout: 1)
        XCTAssertTrue(stub.invalidated, "must invalidate once the interval elapses")
    }

    func test_reuseForInterval_clearsCachedContextAfterInterval() {
        var count = 0
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            contextFactory: {
                count += 1
                return StubLAContext()
            }
        )
        sut.reuseContext = .forInterval(0.05)

        let first = sut.context
        XCTAssertEqual(count, 1)
        XCTAssertTrue(sut.context === first, "must reuse within the interval")

        let cleared = expectation(description: "cached context cleared after interval")
        // The post-expiry callback clears `_context` on the next runloop tick;
        // wait a bit longer than the interval to observe it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            cleared.fulfill()
        }
        wait(for: [cleared], timeout: 1)

        let second = sut.context
        XCTAssertEqual(count, 2, "must build a fresh context after the interval expires")
        XCTAssertFalse(second === first)
    }
}
