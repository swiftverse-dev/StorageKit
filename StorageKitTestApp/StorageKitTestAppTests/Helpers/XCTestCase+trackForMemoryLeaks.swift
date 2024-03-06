//
//  XCTestCase+trackForMemoryLeaks.swift
//  StorageKitTestAppTests
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import XCTest

extension XCTestCase{
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line){
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
