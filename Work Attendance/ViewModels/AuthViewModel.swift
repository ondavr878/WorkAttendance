import SwiftUI
import FirebaseAuth
import GoogleSignIn
import Observation

enum AuthMethod {
    case phone, email
}

@Observable
final class AuthViewModel {
    // Dependencies
    private let authService: AuthServiceProtocol
    
    // State
    var authMethod: AuthMethod = .phone
    var phoneNumber = ""
    var verificationCode = ""
    var verificationID: String?
    var isOTPSent = false
    
    var email = ""
    var password = ""
    var isSignUp = false
    
    var isLoading = false
    var errorMessage: String?
    var showError = false
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    // MARK: - Actions
    
    func handleAction() {
        // Validation / Logic to dispatch to correct method
        guard checkConfiguration() else { return }
        
        Task { [weak self] in
            guard let self = self else { return }
            await self.performAction()
        }
    }
    
    @MainActor
    private func performAction() async {
        if authMethod == .phone {
            if isOTPSent {
                await verifyOTP()
            } else {
                await sendOTP()
            }
        } else {
            if isSignUp {
                await registerWithEmail()
            } else {
                await loginWithEmail()
            }
        }
    }
    
    func loginAnonymously() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            do {
                try await authService.signInAnonymously()
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }
    
    func signInWithGoogle(rootViewController: UIViewController) {
        Task { @MainActor in
            guard let clientID = authService.getGoogleClientID() else {
                 errorMessage = "Configuration Error: No Client ID found."
                 showError = true
                 return
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
                let user = result.user
                guard let idToken = user.idToken?.tokenString else {
                    return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: user.accessToken.tokenString)
                
                await signIn(with: credential)
            } catch {
                if (error as NSError).code == GIDSignInError.canceled.rawValue {
                    return // User cancelled, do nothing
                }
                handleError(error)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private func sendOTP() async {
        guard checkConfiguration() else { return }
        
        isLoading = true
        errorMessage = nil
        
        var cleanedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedPhone.hasPrefix("+") {
            cleanedPhone = "+" + cleanedPhone
        }
        
        do {
            let verID = try await authService.verifyPhoneNumber(cleanedPhone)
            self.verificationID = verID
            withAnimation {
                self.isOTPSent = true
            }
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    private func verifyOTP() async {
        guard let verificationID = verificationID else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(with: verificationID, code: verificationCode)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    private func loginWithEmail() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(withEmail: email, password: password)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    private func registerWithEmail() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.createUser(withEmail: email, password: password)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    private func signIn(with credential: AuthCredential) async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(with: credential)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
        showError = true
    }
    
    private func checkConfiguration() -> Bool {
        if authService.getGoogleClientID() == nil {
            errorMessage = "Missing Configuration! Please ensure GoogleService-Info.plist has REVERSED_CLIENT_ID."
            showError = true
            return false
        }
        return true
    }
    
    // Helper for Button Title
    var actionButtonTitle: String {
        if authMethod == .phone {
            return isOTPSent ? "Verify Code" : "Send Code"
        } else {
            return isSignUp ? "Sign Up" : "Login"
        }
    }
}
