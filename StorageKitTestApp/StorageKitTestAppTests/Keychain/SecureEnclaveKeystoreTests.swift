//
//  SecureEnclaveKeystoreTests.swift
//  StorageKitTestAppTests
//
//  Runs where `Keystore.SecureEnclaveVault.isAvailable` is true: devices, Apple
//  silicon Macs and the iOS simulator on Apple silicon. Skips elsewhere. Real
//  biometry is a manual check on a device.
//

import Foundation
import Testing
import StorageKit

@Suite(.enabled(if: Keystore.SecureEnclaveVault.isAvailable))
final class SecureEnclaveKeystoreIntegrationTests {

    private let runId = UUID().uuidString.prefix(8)
    private let message = Data("one-time password seed".utf8)

    @Test func `a Secure Enclave key generates, loads, decrypts, signs and deletes`() throws {
        let sut = makeSUT()
        defer { sut.deleteKey(for: "knownTag") }

        let generated = try sut.generateKey(forTag: "knownTag")
        let loaded = try sut.loadKey(for: "knownTag")
        #expect(loaded.publicKey.data == generated.publicKey.data)

        let ciphertext = try Keystore.SecureEnclaveKey.encrypt(message, for: loaded.publicKey)
        #expect(try loaded.decrypt(ciphertext) == message)

        let signature = try loaded.sign(message)
        #expect(Keystore.SecureEnclaveKey.verify(signature, of: message, with: generated.publicKey))

        #expect(sut.deleteKey(for: "knownTag"))
        #expect(throws: (any Error).self) {
            try sut.loadKey(for: "knownTag")
        }
    }

    @Test func `a Secure Enclave private key cannot be exported`() throws {
        let sut = makeSUT()
        defer { sut.deleteKey(for: "exportTag") }

        let key = try sut.generateKey(forTag: "exportTag")

        #expect(key.privateKey.data == nil)
        #expect(key.publicKey.data != nil)
    }
}

private extension SecureEnclaveKeystoreIntegrationTests {
    func makeSUT() -> Keystore.SecureEnclaveVault {
        Keystore.SecureEnclaveVault(storeId: "test.secureenclave.integration.\(runId)")
    }
}
