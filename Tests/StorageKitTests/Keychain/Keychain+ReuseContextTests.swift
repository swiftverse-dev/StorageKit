//
//  Keychain+ReuseContextTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class KeychainReuseContextTests: XCTestCase {

    func test_never_producesFreshContextEachAccess() {
        let count = Counter()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            reuseContext: .never,
            contextFactory: { count.increment(); return StubLAContext() }
        )

        _ = sut.context
        _ = sut.context
        _ = sut.context

        XCTAssertEqual(count.value, 3)
    }

    func test_always_reusesTheSameContext() {
        let count = Counter()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            reuseContext: .always,
            contextFactory: { count.increment(); return StubLAContext() }
        )

        let first = sut.context
        let second = sut.context
        let third = sut.context

        XCTAssertEqual(count.value, 1)
        XCTAssertTrue(first === second)
        XCTAssertTrue(second === third)
    }

    func test_forInterval_reusesContextDuringInterval() {
        let count = Counter()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: InMemoryKeychain(),
            reuseContext: .forInterval(60),
            contextFactory: { count.increment(); return StubLAContext() }
        )

        let first = sut.context
        let second = sut.context

        XCTAssertEqual(count.value, 1)
        XCTAssertTrue(first === second)
    }
}
