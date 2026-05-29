//
//  XCTestCase+trackForMemoryLeaks.swift
//  StorageKitTests
//

import XCTest

extension XCTestCase{
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line){
        // `nonisolated(unsafe)` is safe here: the weak reference is only ever
        // read on the test teardown thread, after the test body has finished.
        nonisolated(unsafe) weak var weakInstance = instance
        addTeardownBlock {
            XCTAssertNil(weakInstance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
