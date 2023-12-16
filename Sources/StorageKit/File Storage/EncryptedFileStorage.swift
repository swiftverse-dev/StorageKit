//
//  EncryptedFileStorage.swift
//  JiffySdk
//
//  Created by Lorenzo Limoli on 17/11/22.
//

import Foundation

public final class EncryptedFileStorage: Storage{
    
    public enum Error: Swift.Error{
        case itemNotFound
        case encodeFailure
        case decodeFailure
        case writingFailure
        case unexpectedError
    }
    
    private static let defaultFolder = Bundle(for: EncryptedFileStorage.self).bundleIdentifier ?? "" + ".encryptedFile.storage"
    
    private let fileManager = FileManager.default
    private let folderURL: URL
    private let writingOptions: Data.WritingOptions
    private let readingOptions: Data.ReadingOptions
    
    public init(
        root: URL? = nil,
        folder: String? = nil,
        writingOptions: Data.WritingOptions = .completeFileProtectionUnlessOpen,
        readingOptions: Data.ReadingOptions = .mappedIfSafe
    ) throws {
        let folder = folder ?? Self.defaultFolder
        
        self.writingOptions = writingOptions
        self.readingOptions = readingOptions
        
        var folderURL = root
        if folderURL == nil{
            folderURL = try fileManager.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
            )
        }
        self.folderURL = folderURL!
        .appendingPathComponent(folder)
    }
    
    private static func create(file url: URL) throws {
        let folder = url.deletingLastPathComponent()
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: folder.path) {
            do{
                try fileManager.createDirectory(
                    at: folder,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }catch{
                throw Error.unexpectedError
            }
        }
    }
    
    private static func run<T>(block: () throws -> T, throwing err: Error) throws -> T{
        do{
            return try block()
        }catch{
            throw err
        }
    }
    
    private func fileURL(withName name: String) -> URL{
        folderURL.appendingPathComponent(name)
    }
}

public extension EncryptedFileStorage{
    func save(_ data: Data, withTag tag: String) throws {
        let fileURL = fileURL(withName: tag)
        self.deleteItem(withTag: tag)
        try Self.create(file: fileURL)
        try Self.run(block: {
            try data.write(to: fileURL, options: writingOptions)
        }, throwing: Error.writingFailure)
    }
    
    func save<T: Encodable>(_ object: T, withTag tag: String) throws {
        guard let data = try? JSONEncoder().encode(object) else{
            throw Error.encodeFailure
        }
        try save(data, withTag: tag)
    }
}

public extension EncryptedFileStorage{
    func loadData(withTag tag: String) throws -> Data {
        let fileURL = fileURL(withName: tag)
        return try Self.run(block: {
            try Data(contentsOf: fileURL, options: readingOptions)
        }, throwing: Error.itemNotFound)
    }
    
    func loadObject<T: Decodable>(withTag tag: String) throws -> T{
        let retrievedData = try loadData(withTag: tag)
        
        guard let json = try? JSONDecoder().decode(T.self, from: retrievedData) else{
            throw Error.decodeFailure
        }
        
        return json
    }
}

public extension EncryptedFileStorage{
    
    @discardableResult
    func deleteItem(withTag tag: String) -> Bool {
        let fileURL = fileURL(withName: tag)
        guard let _ = try? fileManager.removeItem(at: fileURL) else { return false }
        return true
    }
}
