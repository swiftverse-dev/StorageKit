//
//  EncryptedFileStorageTests.swift
//  StorageKitTests
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation
import Testing
import StorageKit

final class EncryptedFileStorageTests: StorageTests {
    typealias Error = EncryptedFileStorage.Error

    // Swift Testing builds a fresh instance per `@Test` and runs tests in
    // parallel, so every folder is namespaced with a per-instance id: these
    // tests hit the real filesystem and used to share one directory.
    private let runId = UUID().uuidString.prefix(8)
    private var createdFolders: [URL] = []

    deinit {
        for folder in createdFolders {
            try? FileManager.default.removeItem(at: folder)
        }
    }

    // MARK: Tests for StorageTests protocol
    @Test func `saving data succeeds`() throws {
        let sut = try makeSUT()

        assert_saveData_succeeds(sut: sut, someTag: someTag)
    }

    @Test func `saving data overrides the previously stored value`() throws {
        let sut = try makeSUT()

        try assert_saveData_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }

    @Test func `saving an object succeeds`() throws {
        let sut = try makeSUT()

        assert_saveObject_succeeds(sut: sut, someTag: someTag)
    }

    @Test func `saving an object overrides the previously stored value`() throws {
        let sut = try makeSUT()

        try assert_saveObject_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }

    @Test func `loading data throws itemNotFound on an unknown tag`() throws {
        let sut = try makeSUT()

        try assert_loadData_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }

    @Test func `loading data returns the data previously saved`() throws {
        let sut = try makeSUT()

        try assert_loadData_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }

    @Test func `loading an object throws itemNotFound on an unknown tag`() throws {
        let sut = try makeSUT()

        try assert_loadObj_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }

    @Test func `loading an object returns the object previously saved`() throws {
        let sut = try makeSUT()

        try assert_loadObj_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }

    @Test func `loading an object throws decodeFailure on a wrong object schema`() throws {
        let sut = try makeSUT()

        try assert_loadObj_throwsDecodeFailureOnWrongObjectSchema(sut: sut, someTag: someTag, error: .decodeFailure)
    }

    @Test func `deleting an unknown tag returns false`() throws {
        let sut = try makeSUT()

        assert_delete_returnsFalseOnUnknownTag(sut: sut)
    }

    @Test func `deleting a known tag returns true`() throws {
        let sut = try makeSUT()

        try assert_delete_returnsTrueOnKnownTag(sut: sut, someTag: someTag)
    }

    @Test func `clear returns true and deletes every item of the storage`() throws {
        try assert_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage(sut: makeSUT(folder:))
    }

    @Test func `clear returns false when the storage is empty`() throws {
        let sut = try makeSUT(folder: "test.folder1")

        try assert_clear_returnsFalseWhenThereAreNoItemsInTheStorage(sut: sut)
    }

    // MARK: Specific SUT tests
    @Test func `saving data can create the same file in different folders`() throws {
        let sut1 = try makeSUT(folder: "testOne.encryptedFile.storage")

        let someData1 = Data("some data 1".utf8)
        try sut1.save(someData1, withTag: someTag)

        let sut2 = try makeSUT(folder: "testTwo.encryptedFile.storage")

        let someData2 = Data("some data 2".utf8)
        try sut2.save(someData2, withTag: someTag)

        let retrievedData1 = try sut1.loadData(withTag: someTag)
        let retrievedData2 = try sut2.loadData(withTag: someTag)

        #expect(retrievedData2 != retrievedData1)
        #expect(retrievedData1 == someData1)
        #expect(retrievedData2 == someData2)
    }
}

private extension EncryptedFileStorageTests {
    var someTag: String { "someTag" }

    var root: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }

    func makeSUT(folder: String = "test.encrypted.storage") throws -> any Storage {
        let folder = "\(folder).\(runId)"
        let sut = try EncryptedFileStorage(root: root, folder: folder)
        createdFolders.append(root.appendingPathComponent(folder))
        return sut
    }
}
