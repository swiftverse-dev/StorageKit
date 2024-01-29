//
//  LAContext+reuseForInterval.swift
//
//
//  Created by Lorenzo Limoli on 29/01/24.
//

import Foundation
import LocalAuthentication


extension LAContext {
    func reuse(for interval: TimeInterval, completion: @escaping (LAContext) -> Void) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { timer in
            timer.invalidate()
            self.invalidate()
            completion(self)
        }
    }
}
