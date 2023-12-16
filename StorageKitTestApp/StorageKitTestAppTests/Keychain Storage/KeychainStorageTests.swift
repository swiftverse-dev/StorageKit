//
//  KeychainStorageTests.swift
//  StorageKitTests
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import XCTest
import StorageKit

final class KeychainStorageTests: XCTestCase, StorageTests {
    typealias Error = KeychainStorageError
    
    func test_saveData_succeeds() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)

        assert_saveData_succeeds(sut: sut, someTag: someTag)
    }
    
    func test_saveData_overridesPreviouslyStoredValue() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_saveData_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }
    
    func test_saveObject_succeeds() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        assert_saveObject_succeeds(sut: sut, someTag: someTag)
    }
    
    func test_saveObject_overridesPreviouslyStoredValue() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_saveObject_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }
    
    func test_loadData_throwsItemNotFoundOnUnknownTag() throws{
        let sut = makeSUT()
        try assert_loadData_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }
    
    func test_loadData_returnsTheDataPreviouslySaved() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_loadData_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }
    
    func test_loadObj_throwsItemNotFoundOnUnknownTag() throws{
        let sut = makeSUT()
        
        try assert_loadObj_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }
    
    func test_loadObj_returnsTheDataPreviouslySaved() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_loadObj_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }
    
    func test_loadObj_throwsDecodeFailureOnWrongObjectSchema() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_loadObj_throwsDecodeFailureOnWrongObjectSchema(sut: sut, someTag: someTag, error: .decodeFailure)
    }
    
    func test_delete_returnsFalseOnUnknownTag() throws{
        let sut = makeSUT()
        assert_delete_returnsFalseOnUnknownTag(sut: sut)
    }
    
    func test_delete_returnsTrueOnKnownTag() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_delete_returnsTrueOnKnownTag(sut: sut, someTag: someTag)
    }
    
    // MARK: SPECIFIC SUT TESTS
    func test_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage() throws {
        let someData = Data("someData".utf8)
        let sut1 = makeSUT(storeId: "test.keychain.storage1")
        try sut1.save(someData, withTag: "tag1")
        try sut1.save(someData, withTag: "tag2")
        
        let sut2 = makeSUT(storeId: "test.keychain.storage2")
        try sut2.save(someData, withTag: "tag1")
        
        XCTAssertTrue(sut1.clear())
        XCTAssertThrowsError(try sut1.loadData(withTag: "tag1"))
        XCTAssertThrowsError(try sut1.loadData(withTag: "tag2"))
        
        XCTAssertEqual(try sut2.loadData(withTag: "tag1"), someData)
        
        addTeardownBlock {
            sut1.deleteItem(withTag: "tag1")
            sut1.deleteItem(withTag: "tag2")
            sut2.deleteItem(withTag: "tag1")
        }
    }
    
    func test_clear_returnsFalseWhenThereAreNoItemsInTheStorage() throws {
        let sut = makeSUT(storeId: "test.keychain.storage1")
        
        XCTAssertFalse(sut.clear())
    }

}

private extension KeychainStorageTests{
    var someTag: String{ "someTag" }
    
    func makeSUT(storeId: String = "test.keychain.storage", tagToDelete: String? = nil) -> KeychainDataStorage{
        let sut = KeychainDataStorage(storeId: storeId, protection: .whenUnlocked, itemClass: kSecClassInternetPassword)
        let someTag = tagToDelete ?? someTag
        addTeardownBlock {
            sut.deleteItem(withTag: someTag)
        }
        return sut
    }
}
