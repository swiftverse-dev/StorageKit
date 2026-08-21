//
//  Keychain+ErrorTests.swift
//  StorageKitTests
//

import Foundation
import Testing
@testable import StorageKit

final class KeychainErrorTests: LeakTrackingTestCase {

    @Test func `loadData throws itemNotFound when the keychain reports errSecItemNotFound`() {
        let sut = makeSUT(copyStatus: errSecItemNotFound)

        #expect(throws: Keychain.Error.itemNotFound) {
            try sut.loadData(withTag: "anything")
        }
    }

    @Test func `loadData throws authenticationFailure when the keychain reports errSecAuthFailed`() {
        let sut = makeSUT(copyStatus: errSecAuthFailed)

        #expect(throws: Keychain.Error.authenticationFailure) {
            try sut.loadData(withTag: "anything")
        }
    }

    @Test func `loadData throws unexpectedFailure on an unknown status`() {
        let sut = makeSUT(copyStatus: -99999)

        #expect(throws: Keychain.Error.unexpectedFailure) {
            try sut.loadData(withTag: "anything")
        }
    }

    @Test func `error init returns nil for a success status`() {
        #expect(Keychain.Error(from: errSecSuccess) == nil)
        #expect(Keychain.Error(from: noErr) == nil)
    }

    @Test func `error init maps the known status codes`() {
        #expect(Keychain.Error(from: errSecUserCanceled) == .userCancelOperation)
        #expect(Keychain.Error(from: errSecNotAvailable) == .storeNotAvailable)
        #expect(Keychain.Error(from: errSecItemNotFound) == .itemNotFound)
        #expect(Keychain.Error(from: errSecInteractionNotAllowed) == .passcodeDisabled)
        #expect(Keychain.Error(from: errSecDecode) == .decodeFailure)
        #expect(Keychain.Error(from: errSecAuthFailed) == .authenticationFailure)
    }
}

private extension KeychainErrorTests {
    func makeSUT(copyStatus: OSStatus) -> KeychainStorage {
        let fake = InMemoryKeychain()
        fake.copyStatusOverride = copyStatus
        let sut = KeychainSUTFactory.makeKeychainStorage(performer: fake)
        trackForMemoryLeaks(sut)
        return sut
    }
}
