//
//  ContentView.swift
//  StorageKitTestApp
//
//  Created by Lorenzo Limoli on 16/12/23.
//
//  Manual Secure Enclave and biometric keychain checks for a real device. Every action writes one line
//  to the log, so you can read the result without the debugger.
//

import CryptoKit
import Security
import StorageKit
import SwiftUI

struct ContentView: View {
    private enum Protection: String, CaseIterable, Identifiable {
        case none, currentBiometry, passcodeOrAnyBiometry
        var id: Self { self }

        var accessControl: Keystore.AccessControl {
            switch self {
            case .none: .none
            case .currentBiometry: .currentBiometry
            case .passcodeOrAnyBiometry: .passcodeOrAnyBiometry
            }
        }
    }

    private nonisolated static let tag = "lab"
    private nonisolated static let message = Data("one-time password seed".utf8)

    @State private var protection: Protection = .currentBiometry
    @State private var log: [String] = []

    // One store ID per protection, so switching the picker never mixes keys.
    private var vault: Keystore.SecureEnclaveVault {
        Keystore.SecureEnclaveVault(
            storeId: "lab.secureenclave.\(protection.rawValue)",
            accessControl: protection.accessControl,
            promptMessage: "Unlock the StorageKit test key"
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Secure Enclave", value: Keystore.SecureEnclaveVault.isAvailable ? "available" : "NOT available")
                    Picker("Access control", selection: $protection) {
                        ForEach(Protection.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Steps") {
                    Button("1. Generate key") { run("generate", Self.generate) }
                    Button("2. Load key") { run("load", Self.load) }
                    Button("3. Encrypt + decrypt") { run("decrypt", Self.decrypt) }
                    Button("4. Sign + verify") { run("sign", Self.sign) }
                    Button("5. Raw decrypt (shows the error domain)") { run("raw", Self.rawDecrypt) }
                    Button("6. Delete key", role: .destructive) { run("delete", Self.delete) }
                }

                Section("Biometric storage (current biometry)") {
                    Button("A. Save item") { runStorage("save") { try $0.save(Self.message, withTag: Self.tag); return "saved" } }
                    Button("B. Load item") { runStorage("load") { try $0.loadData(withTag: Self.tag) == Self.message ? "loaded, matches" : "loaded, MISMATCH" } }
                    Button("C. Delete item", role: .destructive) { runStorage("delete") { $0.deleteItem(withTag: Self.tag) ? "deleted" : "nothing to delete" } }
                }

                Section("Log") {
                    ForEach(Array(log.enumerated().reversed()), id: \.offset) { entry in
                        Text(entry.element).font(.caption.monospaced())
                    }
                    Button("Clear log") { log.removeAll() }
                }
            }
            .navigationTitle("Keychain lab")
        }
    }
}

private extension ContentView {
    nonisolated static func generate(_ vault: Keystore.SecureEnclaveVault) throws -> String {
        describe(try vault.generateKey(forTag: Self.tag))
    }

    nonisolated static func load(_ vault: Keystore.SecureEnclaveVault) throws -> String {
        describe(try vault.loadKey(for: Self.tag))
    }

    nonisolated static func describe(_ key: Keystore.SecureEnclaveKey) -> String {
        let exported = key.privateKey.data == nil ? "private key NOT exportable (good)" : "private key EXPORTABLE (bad)"
        return "public \(Self.fingerprint(key.publicKey)), \(exported)"
    }

    nonisolated static func decrypt(_ vault: Keystore.SecureEnclaveVault) throws -> String {
        let key = try vault.loadKey(for: Self.tag)
        let ciphertext = try Keystore.SecureEnclaveKey.encrypt(Self.message, for: key.publicKey)
        let plaintext = try key.decrypt(ciphertext)
        return plaintext == Self.message ? "round trip OK" : "round trip MISMATCH"
    }

    nonisolated static func sign(_ vault: Keystore.SecureEnclaveVault) throws -> String {
        let key = try vault.loadKey(for: Self.tag)
        let signature = try key.sign(Self.message)
        let valid = Keystore.SecureEnclaveKey.verify(signature, of: Self.message, with: key.publicKey)
        return valid ? "signature valid" : "signature INVALID"
    }

    // Calls Security directly so the log shows the CFError domain and code
    // that StorageKit maps. Cancel the prompt here to see what a cancel sends.
    nonisolated static func rawDecrypt(_ vault: Keystore.SecureEnclaveVault) throws -> String {
        let key = try vault.loadKey(for: Self.tag)
        let ciphertext = try Keystore.SecureEnclaveKey.encrypt(Self.message, for: key.publicKey)
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateDecryptedData(
            key.privateKey, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, ciphertext as CFData, &error
        )
        guard result == nil, let cfError = error?.takeRetainedValue() else { return "raw decrypt OK" }
        let underlying = (cfError as Error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError
        return "domain \(CFErrorGetDomain(cfError) as String), code \(CFErrorGetCode(cfError))"
            + (underlying.map { " | underlying \($0.domain) \($0.code)" } ?? "")
    }

    nonisolated static func delete(_ vault: Keystore.SecureEnclaveVault) throws -> String {
        vault.deleteKey(for: Self.tag) ? "deleted" : "nothing to delete"
    }

    nonisolated static func fingerprint(_ key: SecKey) -> String {
        guard let data = key.data else { return "none" }
        return SHA256.hash(data: data).prefix(4).map { String(format: "%02x", $0) }.joined()
    }

    // Keychain calls with an access control block until the user answers the
    // prompt, so they run off the main thread.
    func run(_ name: String, _ action: @escaping @Sendable (Keystore.SecureEnclaveVault) throws -> String) {
        let label = "[\(protection.rawValue)] \(name):"
        let vault = vault
        Task.detached {
            let line: String
            do { line = "\(label) \(try action(vault))" }
            catch { line = "\(label) ERROR \(error)" }
            await MainActor.run { log.append(line) }
        }
    }
}

// Checks on a real device that items with a biometric access control load
// back, and that re-enrolling biometry invalidates them (load after A, then
// add a fingerprint/face in Settings, then load again: expect itemNotFound).
private extension ContentView {
    nonisolated static let biometricStorage = KeychainBiometricStorage(
        storeId: "lab.biometric.storage",
        accessControl: .currentBiometry,
        promptMessage: "Unlock the StorageKit test item"
    )

    func runStorage(_ name: String, _ action: @escaping @Sendable (KeychainBiometricStorage) throws -> String) {
        let label = "[biometric storage] \(name):"
        Task.detached {
            let line: String
            do { line = "\(label) \(try action(Self.biometricStorage))" }
            catch { line = "\(label) ERROR \(error)" }
            await MainActor.run { log.append(line) }
        }
    }
}

#Preview {
    ContentView()
}
