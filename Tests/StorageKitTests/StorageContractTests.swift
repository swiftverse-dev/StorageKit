//
//  StorageContractTests.swift
//  StorageKitTests
//
//  The behaviour every `Storage` implementation must satisfy. Each test runs
//  once per entry of `StorageFixture.all`, so a new implementation gets the
//  whole contract by adding one fixture.
//

import Foundation
import Testing
import StorageKit

struct StorageFixture: Sendable, CustomTestStringConvertible {
    let testDescription: String
    let itemNotFound: any Error & Equatable
    let decodeFailure: any Error & Equatable
    let make: @Sendable (_ name: String) throws -> any Storage
    let cleanup: @Sendable (_ name: String) -> Void

    static let all: [StorageFixture] = [.encryptedFile, .userDefaults]
}

extension StorageFixture {
    static let encryptedFile = StorageFixture(
        testDescription: "EncryptedFileStorage",
        itemNotFound: EncryptedFileStorage.Error.itemNotFound,
        decodeFailure: EncryptedFileStorage.Error.decodeFailure,
        make: { try EncryptedFileStorage(root: documents, folder: $0) },
        cleanup: { try? FileManager.default.removeItem(at: documents.appendingPathComponent($0)) }
    )

    static let userDefaults = StorageFixture(
        testDescription: "UserDefaults",
        itemNotFound: UserDefaults.StorageError.itemNotFound,
        decodeFailure: UserDefaults.StorageError.decodeFailure,
        make: { try #require(UserDefaults(suiteName: $0)) },
        cleanup: { UserDefaults().removePersistentDomain(forName: $0) }
    )
}

private let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

final class StorageContractTests {

    // Swift Testing builds a fresh instance per test case and runs them in
    // parallel against real storage, so every store is namespaced per instance.
    private let runId = UUID().uuidString.prefix(8)
    private var cleanups: [() -> Void] = []

    deinit {
        for cleanup in cleanups { cleanup() }
    }

    @Test(arguments: StorageFixture.all)
    func `saving data succeeds`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        try sut.save(someData, withTag: someTag)
    }

    @Test(arguments: StorageFixture.all)
    func `saving data overrides the previously stored value`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        try sut.save(Data("firstData".utf8), withTag: someTag)
        try sut.save(Data("lastData".utf8), withTag: someTag)

        #expect(try sut.loadData(withTag: someTag) == Data("lastData".utf8))
    }

    @Test(arguments: StorageFixture.all)
    func `saving an object succeeds`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        try sut.save(TestObject(), withTag: someTag)
    }

    @Test(arguments: StorageFixture.all)
    func `saving an object overrides the previously stored value`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)
        let last = TestObject(message: "Message2", value: 2)

        try sut.save(TestObject(message: "Message1", value: 1), withTag: someTag)
        try sut.save(last, withTag: someTag)

        #expect(try sut.loadObject(withTag: someTag) as TestObject == last)
    }

    @Test(arguments: StorageFixture.all)
    func `loading data throws itemNotFound on an unknown tag`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        expect(storage.itemNotFound) {
            _ = try sut.loadData(withTag: "unknownTag")
        }
    }

    @Test(arguments: StorageFixture.all)
    func `loading data returns the data previously saved`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        try sut.save(someData, withTag: someTag)

        #expect(try sut.loadData(withTag: someTag) == someData)
    }

    @Test(arguments: StorageFixture.all)
    func `loading an object throws itemNotFound on an unknown tag`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        expect(storage.itemNotFound) {
            _ = try sut.loadObject(withTag: "unknownTag") as TestObject
        }
    }

    @Test(arguments: StorageFixture.all)
    func `loading an object returns the object previously saved`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)
        let object = TestObject()

        try sut.save(object, withTag: someTag)

        #expect(try sut.loadObject(withTag: someTag) as TestObject == object)
    }

    @Test(arguments: StorageFixture.all)
    func `loading an object throws decodeFailure on a wrong object schema`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        try sut.save("SomeObj", withTag: someTag)

        expect(storage.decodeFailure) {
            _ = try sut.loadObject(withTag: someTag) as TestObject
        }
    }

    @Test(arguments: StorageFixture.all)
    func `deleting an unknown tag returns false`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        #expect(sut.deleteItem(withTag: "unknownTag") == false)
    }

    @Test(arguments: StorageFixture.all)
    func `deleting a known tag returns true`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        try sut.save(someData, withTag: someTag)

        #expect(sut.deleteItem(withTag: someTag))
    }

    @Test(arguments: StorageFixture.all)
    func `clear returns true and deletes every item of the storage`(_ storage: StorageFixture) throws {
        let sut1 = try makeSUT(storage, name: "test.folder1")
        try sut1.save(someData, withTag: "tag1")
        try sut1.save(someData, withTag: "tag2")

        let sut2 = try makeSUT(storage, name: "test.folder2")
        try sut2.save(someData, withTag: "tag1")

        #expect(sut1.clear())
        #expect(throws: (any Error).self) { try sut1.loadData(withTag: "tag1") }
        #expect(throws: (any Error).self) { try sut1.loadData(withTag: "tag2") }

        #expect(try sut2.loadData(withTag: "tag1") == someData)
    }

    @Test(arguments: StorageFixture.all)
    func `clear returns false when the storage is empty`(_ storage: StorageFixture) throws {
        let sut = try makeSUT(storage)

        #expect(sut.clear() == false)
    }
}

private struct TestObject: Codable, Equatable {
    var message = "This is a message"
    var value = 10
}

private extension StorageContractTests {
    var someData: Data { Data("some data".utf8) }
    var someTag: String { "someTag" }

    func makeSUT(_ storage: StorageFixture, name: String = "test.storage") throws -> any Storage {
        let name = "\(name).\(runId)"
        cleanups.append { storage.cleanup(name) }
        return try storage.make(name)
    }

    /// Opens the fixture's `any Error & Equatable` so `#expect(throws:)` can
    /// compare against the concrete error type.
    func expect<E: Error & Equatable>(
        _ error: E,
        sourceLocation: SourceLocation = #_sourceLocation,
        performing body: () throws -> Void
    ) {
        #expect(throws: error, sourceLocation: sourceLocation, performing: body)
    }
}
