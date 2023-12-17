//
//  UserDefaultsStorageTests.swift
//  StorageKitTestAppTests
//
//  Created by Lorenzo Limoli on 16/12/23.
//

import XCTest
import StorageKit

final class UserDefaultsStorageTests: XCTestCase, StorageTests {
    typealias Error = UserDefaults.StorageError
    
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
        try assert_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage(sut: makeSUT(storeId:))
    }
    
    func test_clear_returnsFalseWhenThereAreNoItemsInTheStorage() throws {
        let sut = try makeSUT()
        try assert_clear_returnsFalseWhenThereAreNoItemsInTheStorage(sut: sut)
    }
}

private extension UserDefaultsStorageTests{
    var someTag: String{ "someTag" }
    
    func makeSUT(storeId: String? = nil) throws -> Storage{
        let sut = UserDefaults(suiteName: storeId ?? "test.storeadsdasdas")!
        addTeardownBlock {
            sut.clear()
        }
        return sut
    }

}
