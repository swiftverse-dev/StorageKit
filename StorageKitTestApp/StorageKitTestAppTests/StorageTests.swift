//
//  StorageTests.swift
//  StorageKitTests
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import XCTest
import StorageKit

protocol StorageTests: XCTestCase {
    associatedtype Error: Swift.Error & Equatable
    
    func test_saveData_succeeds() throws
    func test_saveData_overridesPreviouslyStoredValue() throws
    
    func test_saveObject_succeeds() throws
    func test_saveObject_overridesPreviouslyStoredValue() throws
    
    func test_loadData_throwsItemNotFoundOnUnknownTag() throws
    func test_loadData_returnsTheDataPreviouslySaved() throws
    
    func test_loadObj_throwsItemNotFoundOnUnknownTag() throws
    func test_loadObj_returnsTheDataPreviouslySaved() throws
    func test_loadObj_throwsDecodeFailureOnWrongObjectSchema() throws
    
    func test_delete_returnsFalseOnUnknownTag() throws
    func test_delete_returnsTrueOnKnownTag() throws
    func test_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage() throws
    func test_clear_returnsFalseWhenThereAreNoItemsInTheStorage() throws
}

extension StorageTests{
    func assert_saveData_succeeds(sut: Storage, someTag: String, file: StaticString = #file, line: UInt = #line){
        let someData = someData
        expect(error: nil, whileExecuting: {
            try sut.save(someData, withTag: someTag)
        }, file: file, line: line)
    }
    
    
    func assert_saveData_overridesPreviouslyStoredValue(sut: Storage, someTag: String, file: StaticString = #file, line: UInt = #line) throws{
        
        let firstData = "firstData".data(using: .utf8)!
        try sut.save(firstData, withTag: someTag)
        
        let lastData = "lastData".data(using: .utf8)!
        try sut.save(lastData, withTag: someTag)
        
        expect(sut, toRetrieveDataResult: .success(lastData), for: someTag, file: file, line: line)
    }
    
    func assert_saveObject_succeeds(sut: Storage, someTag: String, file: StaticString = #file, line: UInt = #line){
        let someTestObj = someTestObject()
        
        expect(error: nil, whileExecuting: {
            try sut.save(someTestObj, withTag: someTag)
        }, file: file, line: line)
    }
    
    func assert_saveObject_overridesPreviouslyStoredValue(sut: Storage, someTag: String, file: StaticString = #file, line: UInt = #line) throws{
        
        let firstData = someTestObject(message: "Message1", value: 1)
        try sut.save(firstData, withTag: someTag)
        
        let lastData = someTestObject(message: "Message2", value: 2)
        try sut.save(lastData, withTag: someTag)
        
        expect(sut, toRetrieveObjectResult: .success(lastData), for: someTag, file: file, line: line)
    }
    
    func assert_loadData_throwsItemNotFoundOnUnknownTag(sut: Storage, error: Error, file: StaticString = #file, line: UInt = #line) throws{
        let unknownTag = "unknownTag"
        
        expect(sut, toRetrieveDataResult: .failure(error), for: unknownTag, file: file, line: line)
    }
    
    func assert_loadData_returnsTheDataPreviouslySaved(sut: Storage, someTag: String, file: StaticString = #file, line: UInt = #line) throws{
        let someData = someData
        
        try sut.save(someData, withTag: someTag)
        expect(sut, toRetrieveDataResult: .success(someData), for: someTag, file: file, line: line)
    }
    
    func assert_loadObj_throwsItemNotFoundOnUnknownTag(sut: Storage, error: Error, file: StaticString = #file, line: UInt = #line) throws{
        let unknownTag = "unknownTag"
        
        expect(sut, toRetrieveObjectResult: .failure(error), for: unknownTag, file: file, line: line)
    }
    
    func assert_loadObj_returnsTheDataPreviouslySaved(sut: Storage, someTag: String, file: StaticString = #file, line: UInt = #line) throws{
        let someObj = someTestObject()
        
        try sut.save(someObj, withTag: someTag)
        expect(sut, toRetrieveObjectResult: .success(someObj), for: someTag, file: file, line: line)
    }
    
    func assert_loadObj_throwsDecodeFailureOnWrongObjectSchema(sut: Storage, someTag: String, error: Error, file: StaticString = #file, line: UInt = #line) throws{
        
        let someObj = "SomeObj"
        try sut.save(someObj, withTag: someTag)
        
        expect(sut, toRetrieveObjectResult: .failure(error), for: someTag, file: file, line: line)
    }
    
    func assert_delete_returnsFalseOnUnknownTag(sut: Storage, file: StaticString = #file, line: UInt = #line){
        let unknownTag = "unknownTag"
        
        XCTAssertFalse(sut.deleteItem(withTag: unknownTag), file: file, line: line)
    }
    
    func assert_delete_returnsTrueOnKnownTag(sut: Storage, someTag: String, file: StaticString = #file, line: UInt = #line) throws{
        let someData = someData
        
        try sut.save(someData, withTag: someTag)
        XCTAssertTrue(sut.deleteItem(withTag: someTag), file: file, line: line)
    }
    
    func assert_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage(sut: (String) throws -> Storage, file: StaticString = #file, line: UInt = #line) throws {
        let someData = Data("someData".utf8)
        let sut1 = try sut("test.folder1")
        try sut1.save(someData, withTag: "tag1")
        try sut1.save(someData, withTag: "tag2")
        
        let sut2 = try sut("test.folder2")
        try sut2.save(someData, withTag: "tag1")
        
        XCTAssertTrue(sut1.clear(), file: file, line: line)
        XCTAssertThrowsError(try sut1.loadData(withTag: "tag1"), file: file, line: line)
        XCTAssertThrowsError(try sut1.loadData(withTag: "tag2"), file: file, line: line)
        
        XCTAssertEqual(try sut2.loadData(withTag: "tag1"), someData, file: file, line: line)
    }
    
    func assert_clear_returnsFalseWhenThereAreNoItemsInTheStorage(sut: Storage, file: StaticString = #file, line: UInt = #line) throws {
        XCTAssertFalse(sut.clear(), file: file, line: line)
    }
}

fileprivate struct TestObject: Codable, Equatable{
    let message: String
    let value: Int
}

private extension StorageTests{
    
    var someData: Data{ "some data".data(using: .utf8)! }
    var someTag: String{ "someTag" }
    func someTestObject(message: String? = nil, value: Int? = nil) -> TestObject{
        .init(message: message ?? "This is a message", value: value ?? 10)
    }
    
    func makeSUT(tagToDelete: String? = nil) -> Storage{
        let sut = try! EncryptedFileStorage(folder: "test.encryptedFile.storage")
        let someTag = tagToDelete ?? someTag
        addTeardownBlock {
            sut.deleteItem(withTag: someTag)
        }
        return sut
    }
    
    func expect(_ sut: Storage, toRetrieveDataResult result: Result<Data, Error>, for tag: String, file: StaticString = #file, line: UInt = #line){
        var retrievedResult: Result<Data, Swift.Error>
        do{
            let data = try sut.loadData(withTag: tag)
            retrievedResult = .success(data)
        }catch{
            retrievedResult = .failure(error)
        }
        
        switch (retrievedResult, result){
        case let (.success(retrievedData), .success(expectedData)):
            XCTAssertEqual(retrievedData, expectedData, file: file, line: line)
            
        case let (.failure(retrievedError as Error), .failure(expectedError)):
            XCTAssertEqual(retrievedError, expectedError, file: file, line: line)
            
        default:
            XCTFail("Expected \(result), got \(retrievedResult) instead", file: file, line: line)
        }
    }
    
    func expect(_ sut: Storage, toRetrieveObjectResult result: Result<TestObject, Error>, for tag: String, file: StaticString = #file, line: UInt = #line){
        var retrievedResult: Result<TestObject, Swift.Error>
        do{
            let obj: TestObject = try sut.loadObject(withTag: tag)
            retrievedResult = .success(obj)
        }catch{
            retrievedResult = .failure(error)
        }
        
        switch (retrievedResult, result){
        case let (.success(retrievedData), .success(expectedData)):
            XCTAssertEqual(retrievedData, expectedData, file: file, line: line)
            
        case let (.failure(retrievedError as Error), .failure(expectedError)):
            XCTAssertEqual(retrievedError, expectedError, file: file, line: line)
            
        default:
            XCTFail("Expected \(result), got \(retrievedResult) instead", file: file, line: line)
        }
    }
    
    func expect(error: Error?, whileExecuting block: () throws -> Any, file: StaticString = #file, line: UInt = #line){
        let expectError = error != nil
        do{
            let result = try block()
            if expectError{
                XCTFail("Expected \(error!), got \(result) instead", file: file, line: line)
            }
            
        }catch let catchedError{
            guard expectError else{
                XCTFail("Expected nil, got \(catchedError) instead", file: file, line: line)
                return
            }
            XCTAssertEqual(error, catchedError as? Error, file: file, line: line)
        }
    }
}
