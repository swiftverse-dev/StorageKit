//
//  Keychain+AccessGroupTests.swift
//  StorageKitTests
//

import Foundation
import Testing
@testable import StorageKit

final class KeychainAccessGroupTests: LeakTrackingTestCase {

    @Test func `save sets the access group on the query when one is provided`() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: fake,
            accessGroup: "group.test.SharedKeychain"
        )
        trackForMemoryLeaks(sut)

        try sut.save(Data("payload".utf8), withTag: "tag1")

        let stored = try #require(fake.items.values.first)
        #expect(stored[kSecAttrAccessGroup as String] as? String == "group.test.SharedKeychain")
    }

    @Test func `save omits the access group when none is provided`() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(performer: fake, accessGroup: nil)
        trackForMemoryLeaks(sut)

        try sut.save(Data("payload".utf8), withTag: "tag1")

        let stored = try #require(fake.items.values.first)
        #expect(stored[kSecAttrAccessGroup as String] == nil)
    }
}
