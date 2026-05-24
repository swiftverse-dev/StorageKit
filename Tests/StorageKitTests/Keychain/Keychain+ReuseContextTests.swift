//
//  Keychain+ReuseContextTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class KeychainReuseContextTests: XCTestCase {

    func test_never_producesFreshContextEachAccess() {
        var count = 0
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            contextFactory: {
                count += 1
                return StubLAContext()
            }
        )
        sut.reuseContext = .never

        _ = sut.context
        _ = sut.context
        _ = sut.context

        XCTAssertEqual(count, 3)
    }

    func test_always_reusesTheSameContext() {
        var count = 0
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            contextFactory: {
                count += 1
                return StubLAContext()
            }
        )
        sut.reuseContext = .always

        let first = sut.context
        let second = sut.context
        let third = sut.context

        XCTAssertEqual(count, 1)
        XCTAssertTrue(first === second)
        XCTAssertTrue(second === third)
    }

    func test_forInterval_reusesContextDuringInterval() {
        // We cannot deterministically test the timer expiry from a unit test
        // without a clock seam. Cover the "reuse within the same access" path,
        // which is the part that matters for unit-testable logic.
        var count = 0
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            contextFactory: {
                count += 1
                return StubLAContext()
            }
        )
        sut.reuseContext = .forInterval(60)

        let first = sut.context
        let second = sut.context

        XCTAssertEqual(count, 1)
        XCTAssertTrue(first === second)
    }
}
