//
//  BiometricService.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import LocalAuthentication
import Foundation

class BiometricService {
    static let shared = BiometricService()
    
    private init() {}
    
    func authenticateUser(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometrics are available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.unavailable(error?.localizedDescription ?? "Biometrics not available")
        }
        
        // Evaluate
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                if success {
                    continuation.resume(returning: true)
                } else {
                    if let error = authenticationError {
                        continuation.resume(throwing: BiometricError.authenticationFailed(error.localizedDescription))
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
}

enum BiometricError: LocalizedError {
    case unavailable(String)
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unavailable(let message):
            return "Biometric authentication is not available: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        }
    }
}
