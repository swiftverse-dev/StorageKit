//
//  KeystoreTests.swift
//  StorageKitTestAppTests
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import XCTest
import StorageKit

final class KeystoreTests: XCTestCase {
    
    func test_generateKey_throwsBadKeySizeErrorOnBadKeySize() {
        let sut = makeSUT()

        invalidKeys.forEach{ key in
            expect(error: .badKeySizeError) {
                try sut.generate(key: key)
            }
        }
    }
    
    func test_generateKey_succeedsOnValidKeySize() {
        let sut = makeSUT()
        
        validKeys.forEach{ key in
            expect(error: nil) {
                try sut.generate(key: key)
            }
        }
    }
    
    func test_generateKeyWithTag_storesKeySuccessfullyOnKeychain() {
        let sut = makeSUT()
        XCTAssertNoThrow(try sut.generateRSA(tag: knownTag))
        XCTAssertTrue(sut.deleteKey(for: knownTag))
    }
    
    func test_generateKeyWithTag_overridesPreviouslyStoredKey() throws {
        let sut = makeSUT(tagToRemove: knownTag)
        let key1 = try sut.generateRSA(tag: knownTag)
        let key2 = try sut.generateRSA(tag: knownTag)
        
        XCTAssertNotEqual(key1.data, key2.data)
        let loadedKey = try sut.loadKey(for: knownTag)
        XCTAssertEqual(loadedKey.data, key2.data)
    }
    
    func test_loadKey_throwsItemNotFoundForUnknownTag() {
        let sut = makeSUT()
        expect(error: .keychainError(.itemNotFound)) {
            try sut.loadKey(for: unknownTag)
        }
    }
    
    func test_loadKey_loadSecKeySuccessfullyOnPreviouslyUsedTag() throws {
        let sut = makeSUT(tagToRemove: knownTag)
        _ = try sut.generateRSA(tag: knownTag)
        
        expect(error: nil) {
            try sut.loadKey(for: knownTag)
        }
    }
    
    func test_deleteKey_returnsFalseForUnknownTag() {
        let sut = makeSUT()
        XCTAssertFalse(sut.deleteKey(for: unknownTag))
    }
    
    func test_deleteKey_returnsTrueOnPreviouslyUsedTag() throws {
        let sut = makeSUT()
        _ = try sut.generateRSA(tag: knownTag)
        XCTAssertTrue(sut.deleteKey(for: knownTag))
        expect(error: .keychainError(.itemNotFound)) {
            try sut.loadKey(for: knownTag)
        }
    }
    
    func test_keyFromData_throwsParsingErrorForWrongKeyData() {
        let sut = makeSUT()
        let wrongKeyData = Data("wrong key data".utf8)
        expect(error: .parsingError) {
            try sut.keyFrom(.private(.rsa, data: wrongKeyData))
        }
        
        expect(error: .parsingError) {
            try sut.keyFrom(.public(.rsa, data: wrongKeyData))
        }
    }
    
    func test_keyFromData_succeedsOnValidPrivateKey() {
        let sut = makeSUT()
        let validPrivateKey = privatePkcs1Base64
        expect(error: nil) {
            try sut.keyFrom(.private(.rsa, data: validPrivateKey))
        }
    }
    
    func test_keyFromData_succeedsOnValidPublicKey() {
        let sut = makeSUT()
        let validPublicKey = publicX509
        expect(error: nil) {
            try sut.keyFrom(.public(.rsa, data: validPublicKey))
        }
    }
    
    func test_keyFromDataStoreWithTag_successfullyStoreKeyOnKeychain() throws {
        let sut = makeSUT(tagToRemove: knownTag)
        let validPrivateKey = privatePkcs1Base64
        
        expect(error: nil) {
            try sut.keyFrom(
                .private(.rsa, data: validPrivateKey),
                storingWithTag: knownTag
            )
        }
        
        expect(error: nil) {
            try sut.loadKey(for: knownTag)
        }
    }
    
    func test_keyFromDataStoreWithTag_overridesPreviouslyStoredKey() throws {
        let sut = makeSUT(tagToRemove: knownTag)
        let oldKey = try sut.generateRSA(tag: knownTag)
        
        let validPrivateKey = privatePkcs1Base64
        let expectedKey = try sut.keyFrom(
            .private(.rsa, data: validPrivateKey),
            storingWithTag: knownTag
        )
        let loadedKey = try sut.loadKey(for: knownTag)
        
        XCTAssertNotEqual(loadedKey.data, oldKey.data)
        XCTAssertEqual(loadedKey.data, expectedKey.data)
    }
    
    func test_keyFromDataStoreWithTag_doesNotStorePublicKeyOnKeychain() throws {
        let sut = makeSUT(tagToRemove: knownTag)
        let validPublicKey = publicX509
        
        expect(error: nil) {
            try sut.keyFrom(
                .public(.rsa, data: validPublicKey),
                storingWithTag: knownTag
            )
        }
        
        expect(error: .keychainError(.itemNotFound)) {
            try sut.loadKey(for: knownTag)
        }
    }
}

private extension KeystoreTests {
    var knownTag: String { "knownTag" }
    
    var unknownTag: String { "unknownTag" }
    
    var validKeys: [Keystore.KeyTypeGeneration] {
        [.rsa(bitSize: 1024), .ecPrimeRandom(bitSize: 192)]
    }
    
    var invalidKeys: [Keystore.KeyTypeGeneration] {
        [.rsa(bitSize: 1), .ecPrimeRandom(bitSize: 1)]
    }
    
    var privatePkcs1Base64: Data{
        Data(base64Encoded: "MIIEowIBAAKCAQEAsb5OZZAvM1VfP0J/YoWJOeWtyAUsnhtA35cRc8i98I/KYyGi4xAZ6GZMhIMh9rNcAl9XYcRG3/2rsRALqkT1obiiISkPiZhKH2YW6N85HpvgsdqfqsHapvYOhTTiNv7+CThUZth1S75BqdfvGmHqlZH0luWGpbI3TiNg10hPDFYHhHG3dMusZ+HxgkekaUfvFgay1oVQkkanoe/tSFUDtr6NnYNBUmSX0R35YI3feRPglzIcad+vRkdZ7q7qq1C7tt8RvbdJ+Oo+XnNogbQSE0hhcnqa7HkLrijML1ID/q7qX5TSnjYE7u7abnag1zWlfbdG7i2tUpyBbWmIfhBU2QIDAQABAoIBAGRt6RIN4/2XUVgHFL7wQNdL5WNNOSaks4UicKQBWwEf3fUhPk4Z/OmJU9bT2U7xjR1yDYeaRYmuZWKIdG7iw/96uXEPKE5QlCElp/AwoK+g19bmdq0fF5KbGR0/AkqczaEcCOSLjcscVzHGZr17cfbNH2xbiDb7ebBW4RMDMlb/GVo9BoBGTdW5VmrPTZta54NZBuihF417uLBGjeH5dvd2QJr7Sulgv9gRIOSubqmE11ZKy2yUpFac71yr8MHNK1f9aIUmloYgUTeF+pq4WNT3GtB5gxNTaMWtcOOQ9M0zeyAoWNJATSYwhADtLooIsO8RAkHA0CQ12WYV5sZJjAECgYEA9xMvFEb1B0aVB6sIB7sbEbdON4FXVg2AfEefVEvSbu5OKMfw2KtiAOrLs4Ar/zl2A6JcPgI5jx9KLshH3259YupvxrMRvhG42HrHLav0XBPzEu2rwe9XyUFGobbgUdAlwZ+sg5ucY4TF95P4RxhAlgtw5s6qf7WVrfzguzSrNBkCgYEAuCn7PtSKYGlbUd8P/YDx39RTgQ8wcD+XNoLKZTArvlNYw4KulpRt8dwDiZnCtVhF4NyKh4lYDdna7xqLSZVpzOEA6WFYhUZz3f0QY5dNHnLQS8w/d/Yob1AYTps4GwcrXvPYCrBL2Jfmh+RX/8uZocoBWAPy1DQOEuPzODFgPsECgYEAseBfzotfMIPCGykouNgdnt2HNDKr+8nwrIirznZf43kxT+7SGEsaXWqsiGhIRJDLw8YJ/qJ/aeiu8YtDIzpajvIU0spshZggqcmKx/i6DehW4VO2igKUAtI51YbhbEUcSY95Fa7cIlGebKVc42I0bVGDUMeMvDCwt/gMmvpKH1ECgYB428wvaoo5RUsRyqKSyglxy8TVQKOYNpNEycaLa3Z5m/b3r45l8ZjJjYqgxdCa9Ag/zlv3ILIxvNPJ8JCSRMS/GLZhcmoGZLrrZwVXZlbM8aoy5CKO1nOowVaCV6kVS7oxwTL5qMLNrLo0Wi1KCFKVc504Jrc4fcTyrrfSG80+wQKBgDogaa2tU9gld//C6IHU56Miu+BCn9KN/OLAmmFY6MrcXDeLORauePuzay1mFHH53ELosmtJXvqXl4tim3LKMQjVNQPwDmqQqECdZ79luWdQYYIfwEtkLnDEGwWakbO41ZYu1r1tjEz5LSZNdWXuppoKc3S7LP8SOL+F2Z+zrQXB")!
    }
    
    var publicX509: Data {
        Data(base64Encoded: "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQChKCGc2CZRSFYTujEgBMh9f7mLAsJrT+ij9Zut3FbwdbATXrRhmyFMIqfKjH5cm9eQMuryPWcZJ72XHVCzz0BuhY1zI7C3sg9EfouQdIpmccId2ms/cZZxez7ewSCka2peQ9AZ0KgdA/W1RRmrLjHq778fupWH1231gFmpPj7B7wIDAQAB")!
    }
    
    func makeSUT(tagToRemove: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> Keystore {
        let sut = Keystore(
            storeId: "test.keystore",
            protection: .whenUnlocked
        )
        removeKeyOnTearDown(tag: tagToRemove, using: sut)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    
    func expect(error: Keystore.Error?, whileExecuting block: () throws -> Any, file: StaticString = #file, line: UInt = #line){
        let expectError = error != nil
        do{
            let result = try block()
            if expectError{
                XCTFail("Expected \(error!), got \(result) instead", file: file, line: line)
            }
            
        }catch let catchedError{
            guard expectError else{
                XCTFail("Expected nil, got \(catchedError) instead", file: file, line: line)
                return
            }
            XCTAssertEqual(error, catchedError as? Keystore.Error, file: file, line: line)
        }
    }
    
    private func removeKeyOnTearDown(tag: String?, using sut: Keystore) {
        guard let tag else { return }
        addTeardownBlock { [weak sut] in
            sut?.deleteKey(for: tag)
        }
    }
}

private extension Keystore {
    func generateRSA(tag: String? = nil) throws -> SecKey {
        try generate(key: .rsa, forTag: tag)
    }
}
