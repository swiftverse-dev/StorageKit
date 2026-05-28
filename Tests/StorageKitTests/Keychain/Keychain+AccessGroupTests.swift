//
//  Keychain+AccessGroupTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class KeychainAccessGroupTests: XCTestCase {

    func test_save_setsAccessGroupOnQuery_whenAccessGroupProvided() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(
            performer: fake,
            accessGroup: "group.test.SharedKeychain"
        )

        try sut.save(Data("payload".utf8), withTag: "tag1")

        let stored = fake.items.values.first!
        XCTAssertEqual(stored[kSecAttrAccessGroup as String] as? String, "group.test.SharedKeychain")
    }

    func test_save_omitsAccessGroup_whenAccessGroupNil() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeychainStorage(performer: fake, accessGroup: nil)

        try sut.save(Data("payload".utf8), withTag: "tag1")

        let stored = fake.items.values.first!
        XCTAssertNil(stored[kSecAttrAccessGroup as String])
    }
}
