//
//  EncryptedFileStorageTests.swift
//  StorageKitTests
//
//  Created by Lorenzo Limoli on 17/11/22.
//
//  Shared `Storage` behaviour lives in `StorageContractTests`; this suite only
//  covers what is specific to the file-backed implementation.
//

import Foundation
import Testing
import StorageKit

final class EncryptedFileStorageTests {

    // Swift Testing builds a fresh instance per `@Test` and runs tests in
    // parallel, so every folder is namespaced with a per-instance id: these
    // tests hit the real filesystem and used to share one directory.
    private let runId = UUID().uuidString.prefix(8)
    private var createdFolders: [URL] = []

    deinit {
        for folder in createdFolders {
            try? FileManager.default.removeItem(at: folder)
        }
    }

    @Test func `saving data can create the same file in different folders`() throws {
        let sut1 = try makeSUT(folder: "testOne.encryptedFile.storage")

        let someData1 = Data("some data 1".utf8)
        try sut1.save(someData1, withTag: someTag)

        let sut2 = try makeSUT(folder: "testTwo.encryptedFile.storage")

        let someData2 = Data("some data 2".utf8)
        try sut2.save(someData2, withTag: someTag)

        let retrievedData1 = try sut1.loadData(withTag: someTag)
        let retrievedData2 = try sut2.loadData(withTag: someTag)

        #expect(retrievedData2 != retrievedData1)
        #expect(retrievedData1 == someData1)
        #expect(retrievedData2 == someData2)
    }
}

private extension EncryptedFileStorageTests {
    var someTag: String { "someTag" }

    var root: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }

    func makeSUT(folder: String) throws -> any Storage {
        let folder = "\(folder).\(runId)"
        let sut = try EncryptedFileStorage(root: root, folder: folder)
        createdFolders.append(root.appendingPathComponent(folder))
        return sut
    }
}
