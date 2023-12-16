//
//  EncryptedStorageTests.swift
//  StorageKitTests
//
//  Created by Lorenzo Limoli on 16/11/22.
//

import XCTest
import StorageKit


final class EncryptedStorageTests: XCTestCase, StorageTests {
    typealias Error = KeychainStorageError
    
    func test_saveData_succeeds(){
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)

        assert_saveData_succeeds(sut: sut, someTag: someTag)
    }
    
    func test_saveData_overridesPreviouslyStoredValue() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_saveData_overridesPreviouslyStoredValue(sut: sut, someTag: someTag)
    }
    
    func test_saveObject_succeeds(){
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
    
    func test_delete_returnsFalseOnUnknownTag(){
        let sut = makeSUT()
        assert_delete_returnsFalseOnUnknownTag(sut: sut)
    }
    
    func test_delete_returnsTrueOnKnownTag() throws{
        let someTag = someTag
        let sut = makeSUT(tagToDelete: someTag)
        
        try assert_delete_returnsTrueOnKnownTag(sut: sut, someTag: someTag)
    }
}

private extension EncryptedStorageTests{
    var someTag: String{ "someTag" }
    
    func makeSUT(tagToDelete: String? = nil) -> KeychainStorage{
        let sut = EncryptedStorage(storeId: "test.keychain.storage")
        let someTag = tagToDelete ?? someTag
        addTeardownBlock {
            sut.deleteItem(withTag: someTag)
        }
        return sut
    }
}
