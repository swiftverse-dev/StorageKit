//
//  Keychain+QueryPlatformTests.swift
//  StorageKitTests

import XCTest
@testable import StorageKit

final class KeychainQueryPlatformTests: XCTestCase {

    func test_dataRetrieveQuery_setsOperationPromptOnNonMacOS() throws {
        let stub = StubLAContext()
        let query = try Keychain.Query.createQueryForDataRetrieve(
            tag: "tag",
            itemClass: kSecClassGenericPassword,
            context: stub,
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil,
            promptMessage: "Please authenticate"
        ) as! [String: Any]

        #if os(macOS)
        XCTAssertNil(query[kSecUseOperationPrompt as String])
        XCTAssertEqual(stub.localizedReason, "Please authenticate")
        #else
        XCTAssertEqual(query[kSecUseOperationPrompt as String] as? String, "Please authenticate")
        XCTAssertEqual(stub.localizedReason, "")
        #endif
    }
}
