//
//  KeychainStorage+TagMappingTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class KeychainStorageTagMappingTests: XCTestCase {

    func test_save_storesItemUnderService() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(storeId: "store.A", performer: fake)

        try sut.save(Data("payload".utf8), withTag: "tag1")

        XCTAssertEqual(fake.items.count, 1)
        let stored = fake.items.values.first!
        XCTAssertEqual(stored[kSecAttrAccount as String] as? String, "tag1")
        XCTAssertEqual(stored[kSecAttrService as String] as? String, "store.A")
        XCTAssertEqual(stored[kSecValueData as String] as? Data, Data("payload".utf8))
        XCTAssertEqual(stored[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    func test_loadData_findsItemUnderPrefixedAccount() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(storeId: "store.A", performer: fake)

        try sut.save(Data("payload".utf8), withTag: "tag1")
        let loaded = try sut.loadData(withTag: "tag1")

        XCTAssertEqual(loaded, Data("payload".utf8))
    }

    func test_save_overridesPreviouslyStoredItem() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(storeId: "store.A", performer: fake)

        try sut.save(Data("first".utf8), withTag: "tag1")
        try sut.save(Data("second".utf8), withTag: "tag1")

        XCTAssertEqual(fake.items.count, 1)
        XCTAssertEqual(try sut.loadData(withTag: "tag1"), Data("second".utf8))
    }
}
