//
//  KeychainStorage+ClearTests.swift
//  StorageKitTests
//

import Foundation
import Testing
@testable import StorageKit

final class KeychainStorageClearTests: LeakTrackingTestCase {

    @Test func `clear deletes only the items belonging to its own storeId`() throws {
        let fake = InMemoryKeychain()
        let sutA = makeSUT(storeId: "store.A", performer: fake)
        let sutB = makeSUT(storeId: "store.B", performer: fake)

        try sutA.save(Data("a1".utf8), withTag: "tag1")
        try sutA.save(Data("a2".utf8), withTag: "tag2")
        try sutB.save(Data("b1".utf8), withTag: "tag1")

        #expect(fake.items.count == 3)
        #expect(sutA.clear())

        #expect(fake.items.count == 1)
        let surviving = try #require(fake.items.values.first)
        #expect(surviving[kSecAttrAccount as String] as? String == "tag1")
        #expect(surviving[kSecAttrService as String] as? String == "store.B")
    }

    @Test func `clear returns false when there is nothing to delete`() {
        let sut = makeSUT(storeId: "store.A", performer: InMemoryKeychain())

        #expect(sut.clear() == false)
    }

    @Test func `deleteItem returns true on a known tag and false on an unknown one`() throws {
        let sut = makeSUT(storeId: "store.A", performer: InMemoryKeychain())

        try sut.save(Data("payload".utf8), withTag: "tag1")
        #expect(sut.deleteItem(withTag: "tag1"))
        #expect(sut.deleteItem(withTag: "tag1") == false)
    }
}

private extension KeychainStorageClearTests {
    func makeSUT(storeId: String, performer: any KeychainPerforming) -> KeychainStorage {
        let sut = KeychainSUTFactory.makeKeychainStorage(storeId: storeId, performer: performer)
        trackForMemoryLeaks(sut)
        return sut
    }
}
