//
//  Keychain+BiometricGatingTests.swift
//  StorageKitTests
//

import XCTest
import LocalAuthentication
@testable import StorageKit

final class KeychainBiometricGatingTests: XCTestCase {

    func test_save_throwsPasscodeDisabled_whenPolicyIsDeviceOwnerAuthentication_andContextCannotEvaluate() {
        let fake = InMemoryKeychain()
        let stub = StubLAContext()
        stub.canEvaluateResult = false

        let sut = KeychainSUTFactory.makeKeychainStorage(
            protection: .whenThisDevicePasscodeSet,
            accessControl: .userPresence,
            policy: .deviceOwnerAuthentication,
            performer: fake,
            contextFactory: { stub }
        )

        XCTAssertThrowsError(try sut.save(Data("payload".utf8), withTag: "tag")) { error in
            XCTAssertEqual(error as? Keychain.Error, .passcodeDisabled)
        }
        XCTAssertEqual(fake.items.count, 0)
    }

    func test_save_throwsBiometryDisabled_whenPolicyIsDeviceOwnerAuthenticationWithBiometrics_andContextCannotEvaluate() {
        let fake = InMemoryKeychain()
        let stub = StubLAContext()
        stub.canEvaluateResult = false

        let sut = KeychainSUTFactory.makeKeychainStorage(
            protection: .whenThisDevicePasscodeSet,
            accessControl: .biometryAny,
            policy: .deviceOwnerAuthenticationWithBiometrics,
            performer: fake,
            contextFactory: { stub }
        )

        XCTAssertThrowsError(try sut.save(Data("payload".utf8), withTag: "tag")) { error in
            XCTAssertEqual(error as? Keychain.Error, .biometryDisabled)
        }
    }

    func test_save_succeeds_whenStubReportsCanEvaluate() throws {
        let fake = InMemoryKeychain()
        let stub = StubLAContext()
        stub.canEvaluateResult = true

        let sut = KeychainSUTFactory.makeKeychainStorage(
            protection: .whenThisDevicePasscodeSet,
            accessControl: .userPresence,
            policy: .deviceOwnerAuthentication,
            performer: fake,
            contextFactory: { stub }
        )

        XCTAssertNoThrow(try sut.save(Data("payload".utf8), withTag: "tag"))
        XCTAssertEqual(fake.items.count, 1)
    }
}
