//
//  Optional+orThrow.swift
//  
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation

extension Optional {
    func orThrow(_ error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        return wrapped
    }
}

extension Optional where Wrapped: Error {
    func throwIfExist() throws {
        if let error = self { throw error }
    }
}
