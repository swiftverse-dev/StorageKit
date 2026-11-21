//
//  Keychain+BiometricGatingTests.swift
//  StorageKitTests
//

import Foundation
import Testing
import LocalAuthentication
@testable import StorageKit

final class KeychainBiometricGatingTests: LeakTrackingTestCase {

    @Test func `save throws passcodeDisabled when the device owner policy cannot be evaluated`() {
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
        trackForMemoryLeaks(sut)

        #expect(throws: Keychain.Error.passcodeDisabled) {
            try sut.save(Data("payload".utf8), withTag: "tag")
        }
        #expect(fake.items.isEmpty)
    }

    @Test func `save throws biometryDisabled when the biometrics policy cannot be evaluated`() {
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
        trackForMemoryLeaks(sut)

        #expect(throws: Keychain.Error.biometryDisabled) {
            try sut.save(Data("payload".utf8), withTag: "tag")
        }
    }

    @Test func `save succeeds when the context reports it can evaluate the policy`() throws {
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
        trackForMemoryLeaks(sut)

        try sut.save(Data("payload".utf8), withTag: "tag")

        #expect(fake.items.count == 1)
    }

    @Test(arguments: [
        (LAError.Code.passcodeNotSet, LAPolicy.deviceOwnerAuthenticationWithBiometrics, Keychain.Error.passcodeDisabled),
        (.biometryNotEnrolled, .deviceOwnerAuthenticationWithBiometrics, .biometryNotEnrolled),
        (.biometryLockout, .deviceOwnerAuthenticationWithBiometrics, .biometryLockout),
        (.biometryNotAvailable, .deviceOwnerAuthenticationWithBiometrics, .biometryDisabled),
    ])
    func `save throws the reason reported by the failed policy evaluation`(code: LAError.Code, policy: LAPolicy, expected: Keychain.Error) {
        let stub = StubLAContext()
        stub.canEvaluateResult = false
        stub.canEvaluateError = NSError(domain: LAErrorDomain, code: code.rawValue)

        let sut = KeychainSUTFactory.makeKeychainStorage(
            protection: .whenThisDevicePasscodeSet,
            accessControl: .biometryCurrentSet,
            policy: policy,
            performer: InMemoryKeychain(),
            contextFactory: { stub }
        )
        trackForMemoryLeaks(sut)

        #expect(throws: expected) {
            try sut.save(Data("payload".utf8), withTag: "tag")
        }
    }

    @Test func `save keeps the existing item when the policy pre-check fails`() throws {
        let fake = InMemoryKeychain()
        let stub = StubLAContext()

        let sut = KeychainSUTFactory.makeKeychainStorage(
            protection: .whenThisDevicePasscodeSet,
            accessControl: .biometryCurrentSet,
            policy: .deviceOwnerAuthenticationWithBiometrics,
            performer: fake,
            contextFactory: { stub }
        )
        trackForMemoryLeaks(sut)
        try sut.save(Data("old".utf8), withTag: "tag")

        stub.canEvaluateResult = false
        #expect(throws: Keychain.Error.biometryDisabled) {
            try sut.save(Data("new".utf8), withTag: "tag")
        }

        let stored = try #require(fake.items.values.first)
        #expect(stored[kSecValueData as String] as? Data == Data("old".utf8))
    }

    @Test func `loadData pre-checks the policy without matching on the access control attribute`() throws {
        let fake = InMemoryKeychain()
        let stub = StubLAContext()

        let sut = KeychainSUTFactory.makeKeychainStorage(
            protection: .whenThisDevicePasscodeSet,
            accessControl: .biometryCurrentSet,
            policy: .deviceOwnerAuthenticationWithBiometrics,
            performer: fake,
            contextFactory: { stub }
        )
        trackForMemoryLeaks(sut)
        try sut.save(Data("payload".utf8), withTag: "tag")

        #expect(try sut.loadData(withTag: "tag") == Data("payload".utf8))
        let query = try #require(fake.copyMatchingQueries.last)
        #expect(query[kSecAttrAccessControl as String] == nil)
        #expect(query[kSecUseAuthenticationContext as String] != nil)

        stub.canEvaluateResult = false
        #expect(throws: Keychain.Error.biometryDisabled) {
            try sut.loadData(withTag: "tag")
        }
    }

    @Test(arguments: [
        (KeychainBiometricStorage.AccessControl.passcode, LAPolicy.deviceOwnerAuthentication),
        (.passcodeOrAnyBiometry, .deviceOwnerAuthentication),
        (.currentBiometry, .deviceOwnerAuthenticationWithBiometrics),
        (.anyBiometry, .deviceOwnerAuthenticationWithBiometrics),
    ])
    func `KeychainBiometricStorage derives the policy from its access control by default`(
        accessControl: KeychainBiometricStorage.AccessControl,
        expected: LAPolicy
    ) {
        let sut = KeychainBiometricStorage(storeId: "test.biometric", accessControl: accessControl)
        #expect(sut.policy == expected)
        #expect(KeychainBiometricStorage(storeId: "test.biometric", accessControl: accessControl, policy: .deviceOwnerAuthentication).policy == .deviceOwnerAuthentication)
    }
}
