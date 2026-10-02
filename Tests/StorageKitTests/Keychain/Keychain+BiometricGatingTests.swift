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
}
