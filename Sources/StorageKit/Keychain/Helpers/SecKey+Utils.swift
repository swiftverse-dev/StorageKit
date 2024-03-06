//
//  File.swift
//  
//
//  Created by Lorenzo Limoli on 06/03/24.
//

import Foundation

public extension SecKey {
    var data: Data?{ SecKeyCopyExternalRepresentation(self, nil) as? Data }
    var dataBase64: Data?{ data?.base64EncodedData() }
    var stringBase64: String?{ data?.base64EncodedString() }
}
