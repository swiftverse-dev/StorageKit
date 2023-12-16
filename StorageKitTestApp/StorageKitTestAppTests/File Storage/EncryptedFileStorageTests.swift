//
//  EncryptedFileStorageTests.swift
//  StorageKitTests
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import XCTest
import StorageKit

final class EncryptedFileStorageTests: XCTestCase, StorageTests {
    typealias Error = EncryptedFileStorage.Error
    
    // MARK: Tests for StorageTests protocol
    func test_saveData_succeeds() throws{
        let someTag = someTag
        let sut = try makeSUT()

        assert_saveData_succeeds(sut: sut, someTag: someTag)
    }
    
    func test_saveData_overridesPreviouslyStoredValue() throws{
        let someTag = someTag
        let sut = try makeSUT()
        
        try assert_saveData_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }
    
    func test_saveObject_succeeds() throws{
        let someTag = someTag
        let sut = try makeSUT()
        
        assert_saveObject_succeeds(sut: sut, someTag: someTag)
    }
    
    func test_saveObject_overridesPreviouslyStoredValue() throws{
        let someTag = someTag
        let sut = try makeSUT()
        
        try assert_saveObject_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }
    
    func test_loadData_throwsItemNotFoundOnUnknownTag() throws{
        let sut = try makeSUT()
        try assert_loadData_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }
    
    func test_loadData_returnsTheDataPreviouslySaved() throws{
        let someTag = someTag
        let sut = try makeSUT()
        
        try assert_loadData_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }
    
    func test_loadObj_throwsItemNotFoundOnUnknownTag() throws{
        let sut = try makeSUT()
        
        try assert_loadObj_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }
    
    func test_loadObj_returnsTheDataPreviouslySaved() throws{
        let someTag = someTag
        let sut = try makeSUT()
        
        try assert_loadObj_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }
    
    func test_loadObj_throwsDecodeFailureOnWrongObjectSchema() throws{
        let someTag = someTag
        let sut = try makeSUT()
        
        try assert_loadObj_throwsDecodeFailureOnWrongObjectSchema(sut: sut, someTag: someTag, error: .decodeFailure)
    }
    
    func test_delete_returnsFalseOnUnknownTag() throws {
        let sut = try makeSUT()
        assert_delete_returnsFalseOnUnknownTag(sut: sut)
    }
    
    func test_delete_returnsTrueOnKnownTag() throws{
        let someTag = someTag
        let sut = try makeSUT()
        
        try assert_delete_returnsTrueOnKnownTag(sut: sut, someTag: someTag)
    }
    
    func test_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage() throws {
        try assert_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage(sut: makeSUT(folder:))
    }
    
    func test_clear_returnsFalseWhenThereAreNoItemsInTheStorage() throws {
        let sut = try makeSUT(folder: "test.folder1")
        try assert_clear_returnsFalseWhenThereAreNoItemsInTheStorage(sut: sut)
    }
    
    // MARK: Specific SUT tests
    func test_saveData_canCreateTheSameFileInDifferentFolders() throws{
        let someTag = someTag
        let folderTest1 = "testOne.encryptedFile.storage"
        let sut1 = try makeSUT(folder: folderTest1)

        let someData1 = Data("some data 1".utf8)
        try sut1.save(someData1, withTag: someTag)

        let folderTest2 = "testTwo.encryptedFile.storage"
        let sut2 = try makeSUT(folder: folderTest2)

        let someData2 = Data("some data 2".utf8)
        try sut2.save(someData2, withTag: someTag)

        let retrievedData1 = try sut1.loadData(withTag: someTag)
        let retrievedData2 = try sut2.loadData(withTag: someTag)

        XCTAssertNotEqual(retrievedData2, retrievedData1)
        XCTAssertEqual(retrievedData1, someData1)
        XCTAssertEqual(retrievedData2, someData2)
    }
}

private extension EncryptedFileStorageTests{
    var someTag: String{ "someTag" }
    
    var root: URL{ FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }
    var folderTest: String{ "test.encrypted.storage" }
    
    func makeSUT(folder: String? = nil) throws -> Storage{
        let folder = folder ?? folderTest
        let sut = try EncryptedFileStorage(root: root, folder: folder)
        addTeardownBlock { [weak self] in
            self?.clearDisk(forFolder: folder)
        }
        return sut
    }
    
    func fileURL(folder: String, tag: String) -> URL{
        root.appendingPathComponent(folder)
            .appendingPathComponent(tag)
    }
    
    func clearDisk(forFolder folder: String){
        let fileManager = FileManager.default
        let fileURL = root.appendingPathComponent(folder)
        try? fileManager.removeItem(at: fileURL)
    }
}
