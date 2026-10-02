//
//  Keychain+QueryPlatformTests.swift
//  StorageKitTests

import Foundation
import Testing
@testable import StorageKit

// No SUT object to outlive the test here — these exercise the static query
// builders — so the suite stays a value type with no leak tracking.
struct KeychainQueryPlatformTests {

    @Test func `the data retrieve query sets the data protection keychain flag on macOS`() throws {
        let stub = StubLAContext()
        let query = try #require(Keychain.Query.createQueryForDataRetrieve(
            tag: "tag",
            service: "test.service",
            itemClass: kSecClassGenericPassword,
            context: stub,
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil,
            promptMessage: nil
        ) as? [String: Any])

        #if os(macOS)
        #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
        #else
        #expect(query[kSecUseDataProtectionKeychain as String] == nil)
        #endif
    }

    @Test func `the data store query sets the data protection keychain flag on macOS`() throws {
        let stub = StubLAContext()
        let query = try #require(Keychain.Query.createQueryForDataStore(
            Data("payload".utf8),
            tag: "tag",
            service: "test.service",
            itemClass: kSecClassGenericPassword,
            context: stub,
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil
        ) as? [String: Any])

        #if os(macOS)
        #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
        #else
        #expect(query[kSecUseDataProtectionKeychain as String] == nil)
        #endif
    }

    @Test func `the data retrieve query sets the operation prompt on non-macOS platforms`() throws {
        let stub = StubLAContext()
        let query = try #require(Keychain.Query.createQueryForDataRetrieve(
            tag: "tag",
            service: "test.service",
            itemClass: kSecClassGenericPassword,
            context: stub,
            protection: .whenUnlocked,
            accessControlFlags: [],
            policy: nil,
            promptMessage: "Please authenticate"
        ) as? [String: Any])

        #if os(macOS)
        // `kSecUseOperationPrompt` is iOS-only and deprecated on macOS; the
        // production code can't write it on this platform (compile-time #if).
        // The macOS-arm contract is "set context.localizedReason"; check that.
        #expect(stub.localizedReason == "Please authenticate")
        #else
        #expect(query[kSecUseOperationPrompt as String] as? String == "Please authenticate")
        #expect(stub.localizedReason == "")
        #endif
    }
}
