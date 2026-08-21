//
//  Bool+orThrow.swift
//
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation

extension Bool {
    func orThrow(_ error: any Error) throws {
        if !self { throw error }
    }
}
