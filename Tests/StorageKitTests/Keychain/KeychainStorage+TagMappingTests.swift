//
//  KeychainStorage+TagMappingTests.swift
//  StorageKitTests
//

import Foundation
import Testing
@testable import StorageKit

final class KeychainStorageTagMappingTests: LeakTrackingTestCase {

    @Test func `save stores the item under the storeId service`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)

        try sut.save(Data("payload".utf8), withTag: "tag1")

        #expect(fake.items.count == 1)
        let stored = try #require(fake.items.values.first)
        #expect(stored[kSecAttrAccount as String] as? String == "tag1")
        #expect(stored[kSecAttrService as String] as? String == "store.A")
        #expect(stored[kSecValueData as String] as? Data == Data("payload".utf8))
        #expect(stored[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    @Test func `loadData finds the item stored under the prefixed account`() throws {
        let sut = makeSUT(performer: InMemoryKeychain())

        try sut.save(Data("payload".utf8), withTag: "tag1")
        let loaded = try sut.loadData(withTag: "tag1")

        #expect(loaded == Data("payload".utf8))
    }

    @Test func `save overrides a previously stored item`() throws {
        let fake = InMemoryKeychain()
        let sut = makeSUT(performer: fake)

        try sut.save(Data("first".utf8), withTag: "tag1")
        try sut.save(Data("second".utf8), withTag: "tag1")

        #expect(fake.items.count == 1)
        #expect(try sut.loadData(withTag: "tag1") == Data("second".utf8))
    }
}

private extension KeychainStorageTagMappingTests {
    func makeSUT(performer: any KeychainPerforming) -> KeychainStorage {
        let sut = KeychainSUTFactory.makeKeychainStorage(storeId: "store.A", performer: performer)
        trackForMemoryLeaks(sut)
        return sut
    }
}
