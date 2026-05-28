//
//  KeychainStorageTests.swift
//  StorageKitTestAppTests
//
//  Integration tests — exercise real SecItem* against the host app's keychain.
//

import XCTest
import StorageKit

final class KeychainStorageIntegrationTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        Self.makeSUT().clear()
    }

    func test_save_thenLoad_returnsSameData() throws {
        let sut = makeSUT()
        let payload = Data("payload".utf8)

        try sut.save(payload, withTag: "tag1")
        let loaded = try sut.loadData(withTag: "tag1")

        XCTAssertEqual(loaded, payload)
    }

    func test_save_overwritesPreviousValueForSameTag() throws {
        let sut = makeSUT()

        try sut.save(Data("first".utf8), withTag: "tag1")
        try sut.save(Data("second".utf8), withTag: "tag1")

        XCTAssertEqual(try sut.loadData(withTag: "tag1"), Data("second".utf8))
    }

    func test_loadData_throwsItemNotFound_forUnknownTag() {
        let sut = makeSUT()
        XCTAssertThrowsError(try sut.loadData(withTag: "neverWritten"))
    }

    func test_deleteItem_thenLoadData_throwsItemNotFound() throws {
        let sut = makeSUT()
        try sut.save(Data("payload".utf8), withTag: "tag1")
        XCTAssertTrue(sut.deleteItem(withTag: "tag1"))
        XCTAssertThrowsError(try sut.loadData(withTag: "tag1"))
    }

    func test_clear_removesAllItemsForStoreId() throws {
        let sut = makeSUT()
        try sut.save(Data("a".utf8), withTag: "tagA")
        try sut.save(Data("b".utf8), withTag: "tagB")

        XCTAssertTrue(sut.clear())
        XCTAssertThrowsError(try sut.loadData(withTag: "tagA"))
        XCTAssertThrowsError(try sut.loadData(withTag: "tagB"))
    }
}

private extension KeychainStorageIntegrationTests {
    func makeSUT(storeId: String = "test.keychain.storage.integration") -> KeychainStorage {
        let sut = Self.makeSUT(storeId: storeId)
        addTeardownBlock { sut.clear() }
        return sut
    }

    static func makeSUT(storeId: String = "test.keychain.storage.integration") -> KeychainStorage {
        KeychainStorage(storeId: storeId, protection: .whenUnlocked)
    }
}
