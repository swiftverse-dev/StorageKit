//
//  StorageTests.swift
//  StorageKitTests
//

import Foundation
import Testing
import StorageKit

/// Shared behaviour assertions every `Storage` implementation must satisfy.
///
/// This was previously `protocol StorageTests: XCTestCase` whose requirements
/// were the 13 test methods themselves — that existed only so XCTest's runtime
/// discovery would pick them up off the concrete class. Swift Testing discovers
/// through `@Test`, so the protocol is now purely a bag of shared assertions
/// plus the conformer's error type.
protocol StorageTests {
    associatedtype Error: Swift.Error & Equatable
}

extension StorageTests {
    func assert_saveData_succeeds(sut: any Storage, someTag: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let someData = someData
        expect(error: nil, whileExecuting: {
            try sut.save(someData, withTag: someTag)
        }, sourceLocation: sourceLocation)
    }

    func assert_saveData_overridesPreviouslyStoredValue(sut: any Storage, someTag: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let firstData = Data("firstData".utf8)
        try sut.save(firstData, withTag: someTag)

        let lastData = Data("lastData".utf8)
        try sut.save(lastData, withTag: someTag)

        expect(sut, toRetrieveDataResult: .success(lastData), for: someTag, sourceLocation: sourceLocation)
    }

    func assert_saveObject_succeeds(sut: any Storage, someTag: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let someTestObj = someTestObject()

        expect(error: nil, whileExecuting: {
            try sut.save(someTestObj, withTag: someTag)
        }, sourceLocation: sourceLocation)
    }

    func assert_saveObject_overridesPreviouslyStoredValue(sut: any Storage, someTag: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let firstData = someTestObject(message: "Message1", value: 1)
        try sut.save(firstData, withTag: someTag)

        let lastData = someTestObject(message: "Message2", value: 2)
        try sut.save(lastData, withTag: someTag)

        expect(sut, toRetrieveObjectResult: .success(lastData), for: someTag, sourceLocation: sourceLocation)
    }

    func assert_loadData_throwsItemNotFoundOnUnknownTag(sut: any Storage, error: Error, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let unknownTag = "unknownTag"

        expect(sut, toRetrieveDataResult: .failure(error), for: unknownTag, sourceLocation: sourceLocation)
    }

    func assert_loadData_returnsTheDataPreviouslySaved(sut: any Storage, someTag: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let someData = someData

        try sut.save(someData, withTag: someTag)
        expect(sut, toRetrieveDataResult: .success(someData), for: someTag, sourceLocation: sourceLocation)
    }

    func assert_loadObj_throwsItemNotFoundOnUnknownTag(sut: any Storage, error: Error, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let unknownTag = "unknownTag"

        expect(sut, toRetrieveObjectResult: .failure(error), for: unknownTag, sourceLocation: sourceLocation)
    }

    func assert_loadObj_returnsTheDataPreviouslySaved(sut: any Storage, someTag: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let someObj = someTestObject()

        try sut.save(someObj, withTag: someTag)
        expect(sut, toRetrieveObjectResult: .success(someObj), for: someTag, sourceLocation: sourceLocation)
    }

    func assert_loadObj_throwsDecodeFailureOnWrongObjectSchema(sut: any Storage, someTag: String, error: Error, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let someObj = "SomeObj"
        try sut.save(someObj, withTag: someTag)

        expect(sut, toRetrieveObjectResult: .failure(error), for: someTag, sourceLocation: sourceLocation)
    }

    func assert_delete_returnsFalseOnUnknownTag(sut: any Storage, sourceLocation: SourceLocation = #_sourceLocation) {
        let unknownTag = "unknownTag"

        #expect(sut.deleteItem(withTag: unknownTag) == false, sourceLocation: sourceLocation)
    }

    func assert_delete_returnsTrueOnKnownTag(sut: any Storage, someTag: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let someData = someData

        try sut.save(someData, withTag: someTag)
        #expect(sut.deleteItem(withTag: someTag), sourceLocation: sourceLocation)
    }

    func assert_clear_returnsTrueWhenDeletesAllTheItemsOfTheStorage(sut: (String) throws -> any Storage, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let someData = Data("someData".utf8)
        let sut1 = try sut("test.folder1")
        try sut1.save(someData, withTag: "tag1")
        try sut1.save(someData, withTag: "tag2")

        let sut2 = try sut("test.folder2")
        try sut2.save(someData, withTag: "tag1")

        #expect(sut1.clear(), sourceLocation: sourceLocation)
        #expect(throws: (any Swift.Error).self, sourceLocation: sourceLocation) { try sut1.loadData(withTag: "tag1") }
        #expect(throws: (any Swift.Error).self, sourceLocation: sourceLocation) { try sut1.loadData(withTag: "tag2") }

        #expect(try sut2.loadData(withTag: "tag1") == someData, sourceLocation: sourceLocation)
    }

    func assert_clear_returnsFalseWhenThereAreNoItemsInTheStorage(sut: any Storage, sourceLocation: SourceLocation = #_sourceLocation) throws {
        #expect(sut.clear() == false, sourceLocation: sourceLocation)
    }
}

fileprivate struct TestObject: Codable, Equatable {
    let message: String
    let value: Int
}

private extension StorageTests {

    var someData: Data { Data("some data".utf8) }
    var someTag: String { "someTag" }
    func someTestObject(message: String? = nil, value: Int? = nil) -> TestObject {
        .init(message: message ?? "This is a message", value: value ?? 10)
    }

    func expect(_ sut: any Storage, toRetrieveDataResult result: Result<Data, Error>, for tag: String, sourceLocation: SourceLocation = #_sourceLocation) {
        var retrievedResult: Result<Data, any Swift.Error>
        do {
            let data = try sut.loadData(withTag: tag)
            retrievedResult = .success(data)
        } catch {
            retrievedResult = .failure(error)
        }

        switch (retrievedResult, result) {
        case let (.success(retrievedData), .success(expectedData)):
            #expect(retrievedData == expectedData, sourceLocation: sourceLocation)

        case let (.failure(retrievedError as Error), .failure(expectedError)):
            #expect(retrievedError == expectedError, sourceLocation: sourceLocation)

        default:
            Issue.record("Expected \(result), got \(retrievedResult) instead", sourceLocation: sourceLocation)
        }
    }

    func expect(_ sut: any Storage, toRetrieveObjectResult result: Result<TestObject, Error>, for tag: String, sourceLocation: SourceLocation = #_sourceLocation) {
        var retrievedResult: Result<TestObject, any Swift.Error>
        do {
            let obj: TestObject = try sut.loadObject(withTag: tag)
            retrievedResult = .success(obj)
        } catch {
            retrievedResult = .failure(error)
        }

        switch (retrievedResult, result) {
        case let (.success(retrievedData), .success(expectedData)):
            #expect(retrievedData == expectedData, sourceLocation: sourceLocation)

        case let (.failure(retrievedError as Error), .failure(expectedError)):
            #expect(retrievedError == expectedError, sourceLocation: sourceLocation)

        default:
            Issue.record("Expected \(result), got \(retrievedResult) instead", sourceLocation: sourceLocation)
        }
    }

    func expect(error: Error?, whileExecuting block: () throws -> Any, sourceLocation: SourceLocation = #_sourceLocation) {
        do {
            let result = try block()
            if let error {
                Issue.record("Expected \(error), got \(result) instead", sourceLocation: sourceLocation)
            }
        } catch let caughtError {
            guard let error else {
                Issue.record("Expected nil, got \(caughtError) instead", sourceLocation: sourceLocation)
                return
            }
            #expect(caughtError as? Error == error, sourceLocation: sourceLocation)
        }
    }
}
