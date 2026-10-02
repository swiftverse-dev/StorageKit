//
//  Keystore+AccessControlTests.swift
//  StorageKitTests
//

import LocalAuthentication
import Testing
@testable import StorageKit

struct KeystoreAccessControlTests {

    @Test func `each access control maps to its flags`() {
        #expect(Keystore.AccessControl.none.flags == [])
        #expect(Keystore.AccessControl.passcode.flags == .devicePasscode)
        #expect(Keystore.AccessControl.passcodeOrAnyBiometry.flags == .userPresence)
        #expect(Keystore.AccessControl.currentBiometry.flags == .biometryCurrentSet)
        #expect(Keystore.AccessControl.anyBiometry.flags == .biometryAny)
    }

    @Test func `each access control maps to its policy`() {
        #expect(Keystore.AccessControl.none.policy == nil)
        #expect(Keystore.AccessControl.passcode.policy == .deviceOwnerAuthentication)
        #expect(Keystore.AccessControl.passcodeOrAnyBiometry.policy == .deviceOwnerAuthentication)
        #expect(Keystore.AccessControl.currentBiometry.policy == .deviceOwnerAuthenticationWithBiometrics)
        #expect(Keystore.AccessControl.anyBiometry.policy == .deviceOwnerAuthenticationWithBiometrics)
    }

    @Test func `the standard vault stores the mapped flags and policy`() {
        let sut = KeychainSUTFactory.makeKeystore(accessControl: .currentBiometry, performer: InMemoryKeychain())

        #expect(sut.accessControl == .biometryCurrentSet)
        #expect(sut.policy == .deviceOwnerAuthenticationWithBiometrics)
    }
}
