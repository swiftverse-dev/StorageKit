//
//  Keystore+InstanceTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class KeystoreInstanceTests: XCTestCase {

    func test_loadKey_throwsItemNotFound_forUnknownTag() {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeystore(performer: fake)

        XCTAssertThrowsError(try sut.loadKey(for: "unknown")) { error in
            XCTAssertEqual(error as? Keystore.Error, .keychainError(.itemNotFound))
        }
    }

    func test_deleteKey_returnsFalse_forUnknownTag() {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeystore(performer: fake)
        XCTAssertFalse(sut.deleteKey(for: "unknown"))
    }

    func test_keyFromDataStoreWithTag_storesItemUnderPrefixedApplicationTag() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeystore(storeId: "test.keystore", performer: fake)

        _ = try sut.keyFrom(.private(.rsa, data: KeystoreStaticTests.privatePkcs1Base64), storingWithTag: "knownTag")

        XCTAssertEqual(fake.items.count, 1)
        let stored = fake.items.values.first!
        XCTAssertEqual(stored[kSecAttrApplicationTag as String] as? String, "test.keystore.knownTag")
        XCTAssertEqual(stored[kSecClass as String] as? String, kSecClassKey as String)
    }

    func test_keyFromDataStoreWithTag_doesNotStorePublicKeys() throws {
        let fake = InMemoryKeychain()
        let sut = KeychainSUTFactory.makeKeystore(storeId: "test.keystore", performer: fake)

        _ = try sut.keyFrom(.public(.rsa, data: KeystoreStaticTests.publicX509), storingWithTag: "knownTag")

        XCTAssertEqual(fake.items.count, 0)
    }
}
