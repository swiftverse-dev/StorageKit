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
    
    override class func setUp() {
        super.setUp()
        Self.makeSUT().clear()
    }
    
    func test_saveData_succeeds() throws{
        let someTag = someTag
        let sut = makeSUT()

        assert_saveData_succeeds(sut: sut, someTag: someTag)
    }
    
    func test_saveData_overridesPreviouslyStoredValue() throws{
        let someTag = someTag
        let sut = makeSUT()
        
        try assert_saveData_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }
    
    func test_saveObject_succeeds() throws{
        let someTag = someTag
        let sut = makeSUT()
        
        assert_saveObject_succeeds(sut: sut, someTag: someTag)
    }
    
    func test_saveObject_overridesPreviouslyStoredValue() throws{
        let someTag = someTag
        let sut = makeSUT()
        
        try assert_saveObject_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }
    
    func test_loadData_throwsItemNotFoundOnUnknownTag() throws{
        let sut = makeSUT()
        try assert_loadData_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }
    
    func test_loadData_returnsTheDataPreviouslySaved() throws{
        let someTag = someTag
        let sut = makeSUT()
        
        try assert_loadData_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }
    
    func test_loadObj_throwsItemNotFoundOnUnknownTag() throws{
        let sut = makeSUT()
        
        try assert_loadObj_throwsItemNotFoundOnUnknownTag(sut: sut, error: .itemNotFound)
    }
    
    func test_loadObj_returnsTheDataPreviouslySaved() throws{
        let someTag = someTag
        let sut = makeSUT()
        
        try assert_loadObj_returnsTheDataPreviouslySaved(sut: sut, someTag: someTag)
    }
    
    func test_loadObj_throwsDecodeFailureOnWrongObjectSchema() throws{
        let someTag = someTag
        let sut = makeSUT()
        
        try assert_loadObj_throwsDecodeFailureOnWrongObjectSchema(sut: sut, someTag: someTag, error: .decodeFailure)
    }
    
    func test_delete_returnsFalseOnUnknownTag() throws{
        let sut = makeSUT()
        assert_delete_returnsFalseOnUnknownTag(sut: sut)
    }
    
    func test_delete_returnsTrueOnKnownTag() throws{
        let someTag = someTag
        let sut = makeSUT()
        
        try assert_delete_returnsTrueOnKnownTag(sut: sut, someTag: someTag)
    }
    
    func test_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage() throws {
        try assert_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage(sut: makeSUT(storeId:))
    }
    
    func test_clear_returnsFalseWhenThereAreNoItemsInTheStorage() throws {
        let sut = makeSUT()
        try assert_clear_returnsFalseWhenThereAreNoItemsInTheStorage(sut: sut)
    }

}

private extension KeychainStorageTests{
    var someTag: String{ "someTag" }
    
    func makeSUT(storeId: String = "test.keychain.storage") -> KeychainDataStorage{
        let sut = Self.makeSUT(storeId: storeId)
        addTeardownBlock {
            sut.clear()
        }
        return sut
    }
    
    static func makeSUT(storeId: String = "test.keychain.storage") -> KeychainDataStorage {
        return KeychainDataStorage(storeId: storeId, protection: .whenUnlocked, itemClass: kSecClassGenericPassword)
    }
}
