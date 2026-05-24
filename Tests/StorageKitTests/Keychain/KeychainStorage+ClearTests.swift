//
//  KeychainStorage+ClearTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class KeychainStorageClearTests: XCTestCase {

    func test_clear_deletesOnlyItemsForOwnStoreId() throws {
        let fake = InMemoryKeychain()
        let sutA = KeychainSUTFactory.makeKeychainStorage(storeId: "store.A", performer: fake)
        let sutB = KeychainSUTFactory.makeKeychainStorage(storeId: "store.B", performer: fake)

        try sutA.save(Data("a1".utf8), withTag: "tag1")
        try sutA.save(Data("a2".utf8), withTag: "tag2")
        try sutB.save(Data("b1".utf8), withTag: "tag1")

        XCTAssertEqual(fake.items.count, 3)
        XCTAssertTrue(sutA.clear())

        XCTAssertEqual(fake.items.count, 1)
        let surviving = fake.items.values.first!
        XCTAssertEqual(surviving[kSecAttrAccount as String] as? String, "store.B.tag1")
    }

    func test_clear_returnsFalseWhenNothingToDelete() {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(storeId: "store.A", performer: fake)

        XCTAssertFalse(sut.clear())
    }

    func test_deleteItem_returnsTrueOnKnownTag_andFalseOnUnknown() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(storeId: "store.A", performer: fake)

        try sut.save(Data("payload".utf8), withTag: "tag1")
        XCTAssertTrue(sut.deleteItem(withTag: "tag1"))
        XCTAssertFalse(sut.deleteItem(withTag: "tag1"))
    }
}
