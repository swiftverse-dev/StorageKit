//
//  UserDefaultsStorageTests.swift
//  StorageKitTests
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import Foundation
import Testing
import StorageKit

final class UserDefaultsStorageTests: StorageTests {
    typealias Error = UserDefaults.StorageError

    // Real `UserDefaults` suites, so each test gets its own namespace: Swift
    // Testing runs these in parallel and teardown wipes the whole domain.
    private let runId = UUID().uuidString.prefix(8)
    private var createdSuites: [String] = []

    deinit {
        for suite in createdSuites {
            UserDefaults().removePersistentDomain(forName: suite)
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
        try assert_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage(sut: makeSUT(storeId:))
    }

    @Test func `clear returns false when the storage is empty`() throws {
        let sut = try makeSUT()

        try assert_clear_returnsFalseWhenThereAreNoItemsInTheStorage(sut: sut)
    }
}

private extension UserDefaultsStorageTests {
    var someTag: String { "someTag" }

    func makeSUT(storeId: String = "test.userDefaults.storage") throws -> any Storage {
        let suiteName = "\(storeId).\(runId)"
        let sut = try #require(UserDefaults(suiteName: suiteName))
        createdSuites.append(suiteName)
        return sut
    }
}
