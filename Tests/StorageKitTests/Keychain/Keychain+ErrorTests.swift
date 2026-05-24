//
//  Keychain+ErrorTests.swift
//  StorageKitTests
//

import XCTest
@testable import StorageKit

final class KeychainErrorTests: XCTestCase {

    func test_loadData_throwsItemNotFound_whenFakeReportsItemNotFound() {
        let fake = InMemoryKeychain()
        fake.copyStatusOverride = errSecItemNotFound
        let sut = KeychainSUTFactory.makeKeychainStorage(performer: fake)

        XCTAssertThrowsError(try sut.loadData(withTag: "anything")) { error in
            XCTAssertEqual(error as? Keychain.Error, .itemNotFound)
        }
    }

    func test_loadData_throwsAuthenticationFailure_whenFakeReportsErrSecAuthFailed() {
        let fake = InMemoryKeychain()
        fake.copyStatusOverride = errSecAuthFailed
        let sut = KeychainSUTFactory.makeKeychainStorage(performer: fake)

        XCTAssertThrowsError(try sut.loadData(withTag: "anything")) { error in
            XCTAssertEqual(error as? Keychain.Error, .authenticationFailure)
        }
    }

    func test_loadData_throwsUnexpectedFailure_onUnknownStatus() {
        let fake = InMemoryKeychain()
        fake.copyStatusOverride = -99999
        let sut = KeychainSUTFactory.makeKeychainStorage(performer: fake)

        XCTAssertThrowsError(try sut.loadData(withTag: "anything")) { error in
            XCTAssertEqual(error as? Keychain.Error, .unexpectedFailure)
        }
    }

    func test_keychainErrorInit_returnsNilForSuccess() {
        XCTAssertNil(Keychain.Error(from: errSecSuccess))
        XCTAssertNil(Keychain.Error(from: noErr))
    }

    func test_keychainErrorInit_mapsKnownStatusCodes() {
        XCTAssertEqual(Keychain.Error(from: errSecUserCanceled), .userCancelOperation)
        XCTAssertEqual(Keychain.Error(from: errSecNotAvailable), .storeNotAvailable)
        XCTAssertEqual(Keychain.Error(from: errSecItemNotFound), .itemNotFound)
        XCTAssertEqual(Keychain.Error(from: errSecInteractionNotAllowed), .passcodeDisabled)
        XCTAssertEqual(Keychain.Error(from: errSecDecode), .decodeFailure)
        XCTAssertEqual(Keychain.Error(from: errSecAuthFailed), .authenticationFailure)
    }
}

extension Keychain.Error: Equatable {
    public static func == (lhs: Keychain.Error, rhs: Keychain.Error) -> Bool {
        switch (lhs, rhs) {
        case (.passcodeDisabled, .passcodeDisabled),
             (.biometryDisabled, .biometryDisabled),
             (.itemNotFound, .itemNotFound),
             (.userCancelOperation, .userCancelOperation),
             (.storeNotAvailable, .storeNotAvailable),
             (.decodeFailure, .decodeFailure),
             (.encodeFailure, .encodeFailure),
             (.authenticationFailure, .authenticationFailure),
             (.unexpectedFailure, .unexpectedFailure):
            return true
        default:
            return false
        }
    }
}
