import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

protocol AuthServiceProtocol {
    func verifyPhoneNumber(_ phoneNumber: String) async throws -> String
    func signIn(with verificationID: String, code: String) async throws
    func signIn(withEmail email: String, password: String) async throws
    func createUser(withEmail email: String, password: String) async throws
    func signInAnonymously() async throws
    func signIn(with credential: AuthCredential) async throws
    func getGoogleClientID() -> String?
}

final class AuthService: AuthServiceProtocol {
    func verifyPhoneNumber(_ phoneNumber: String) async throws -> String {
        return try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
    }
    
    func signIn(with verificationID: String, code: String) async throws {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        try await signIn(with: credential)
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func createUser(withEmail email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signInAnonymously() async throws {
        try await Auth.auth().signInAnonymously()
    }
    
    func signIn(with credential: AuthCredential) async throws {
        try await Auth.auth().signIn(with: credential)
    }
    
    func getGoogleClientID() -> String? {
        return FirebaseApp.app()?.options.clientID
    }
}
