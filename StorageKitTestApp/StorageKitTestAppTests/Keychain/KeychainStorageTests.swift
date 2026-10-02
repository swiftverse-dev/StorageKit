//
//  KeychainStorageTests.swift
//  StorageKitTestAppTests
//
//  Integration tests — exercise real SecItem* against the host app's keychain.
//

import Foundation
import Testing
import StorageKit

// Not leak-tracked: the suite deliberately holds its SUTs so `deinit` can wipe
// the real keychain items they created.
final class KeychainStorageIntegrationTests {

    // Every test gets its own store, so the parallel runs can't clear each
    // other's items — `clear()` wipes a whole storeId.
    private let runId = UUID().uuidString.prefix(8)
    private var suts: [KeychainStorage] = []

    deinit {
        for sut in suts { _ = sut.clear() }
    }

    @Test func `saving then loading returns the same data`() throws {
        let sut = makeSUT()
        let payload = Data("payload".utf8)

        try sut.save(payload, withTag: "tag1")
        let loaded = try sut.loadData(withTag: "tag1")

        #expect(loaded == payload)
    }

    @Test func `saving overwrites the previous value for the same tag`() throws {
        let sut = makeSUT()

        try sut.save(Data("first".utf8), withTag: "tag1")
        try sut.save(Data("second".utf8), withTag: "tag1")

        #expect(try sut.loadData(withTag: "tag1") == Data("second".utf8))
    }

    @Test func `loading an unknown tag throws`() {
        let sut = makeSUT()

        #expect(throws: (any Error).self) {
            try sut.loadData(withTag: "neverWritten")
        }
    }

    @Test func `loading a deleted item throws`() throws {
        let sut = makeSUT()

        try sut.save(Data("payload".utf8), withTag: "tag1")

        #expect(sut.deleteItem(withTag: "tag1"))
        #expect(throws: (any Error).self) {
            try sut.loadData(withTag: "tag1")
        }
    }

    @Test func `clear removes every item of the storeId`() throws {
        let sut = makeSUT()
        try sut.save(Data("a".utf8), withTag: "tagA")
        try sut.save(Data("b".utf8), withTag: "tagB")

        #expect(sut.clear())
        #expect(throws: (any Error).self) { try sut.loadData(withTag: "tagA") }
        #expect(throws: (any Error).self) { try sut.loadData(withTag: "tagB") }
    }
}

private extension KeychainStorageIntegrationTests {
    func makeSUT() -> KeychainStorage {
        let sut = KeychainStorage(
            storeId: "test.keychain.storage.integration.\(runId)",
            protection: .whenUnlocked
        )
        suts.append(sut)
        return sut
    }
}
