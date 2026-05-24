//
//  Keychain+QueryPlatformTests.swift
//  StorageKitTests

import XCTest
@testable import StorageKit

final class KeychainQueryPlatformTests: XCTestCase {

    func test_dataRetrieveQuery_setsDataProtectionKeychainOnMacOS() throws {
        let stub = StubLAContext()
        let query = try Keychain.Query.createQueryForDataRetrieve(
            tag: "tag",
            itemClass: kSecClassGenericPassword,
            context: stub,
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil,
            promptMessage: nil
        ) as! [String: Any]

        #if os(macOS)
        XCTAssertEqual(query[kSecUseDataProtectionKeychain as String] as? Bool, true)
        #else
        XCTAssertNil(query[kSecUseDataProtectionKeychain as String])
        #endif
    }

    func test_dataStoreQuery_setsDataProtectionKeychainOnMacOS() throws {
        let stub = StubLAContext()
        let query = try Keychain.Query.createQueryForDataStore(
            Data("payload".utf8),
            tag: "tag",
            itemClass: kSecClassGenericPassword,
            context: stub,
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil
        ) as! [String: Any]

        #if os(macOS)
        XCTAssertEqual(query[kSecUseDataProtectionKeychain as String] as? Bool, true)
        #else
        XCTAssertNil(query[kSecUseDataProtectionKeychain as String])
        #endif
    }

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
