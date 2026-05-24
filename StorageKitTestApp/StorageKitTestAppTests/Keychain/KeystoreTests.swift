//
//  KeystoreTests.swift
//  StorageKitTestAppTests
//
//  Integration tests — exercise real SecKey generation and keychain round-trips.
//

import XCTest
import StorageKit

final class KeystoreIntegrationTests: XCTestCase {

    func test_generateKeyWithTag_storesAndLoadsKey() throws {
        let sut = makeSUT()
        defer { sut.deleteKey(for: "knownTag") }

        XCTAssertNoThrow(try sut.generate(key: .rsa, forTag: "knownTag"))
        XCTAssertNoThrow(try sut.loadKey(for: "knownTag"))
    }

    func test_generateKeyWithTag_overridesPreviouslyStoredKey() throws {
        let sut = makeSUT()
        defer { sut.deleteKey(for: "knownTag") }

        let first = try sut.generate(key: .rsa, forTag: "knownTag")
        let second = try sut.generate(key: .rsa, forTag: "knownTag")

        XCTAssertNotEqual(first.data, second.data)
        let loaded = try sut.loadKey(for: "knownTag")
        XCTAssertEqual(loaded.data, second.data)
    }

    func test_loadKey_throwsItemNotFound_forUnknownTag() {
        let sut = makeSUT()
        XCTAssertThrowsError(try sut.loadKey(for: "unknownTag"))
    }

    func test_deleteKey_returnsFalseForUnknownTag() {
        let sut = makeSUT()
        XCTAssertFalse(sut.deleteKey(for: "unknownTag"))
    }

    func test_deleteKey_returnsTrueOnPreviouslyStoredTag() throws {
        let sut = makeSUT()
        _ = try sut.generate(key: .rsa, forTag: "knownTag")
        XCTAssertTrue(sut.deleteKey(for: "knownTag"))
    }
}

private extension KeystoreIntegrationTests {
    func makeSUT() -> Keystore {
        Keystore(storeId: "test.keystore.integration", protection: .whenUnlocked)
    }
}
