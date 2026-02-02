import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

// AuthMethod enum is now in AuthViewModel or can be kept global if shared, 
// using typealias for backward compatibility or moving it.
// Assuming we keep simple UI but delegate logic.

struct AuthView: View {
    @State private var viewModel = AuthViewModel()
    
    // Animation states (UI specific, keep here)
    @State private var isAnimating = false
    @FocusState private var isFocused: Bool
    
    @State private var showPassword = false
    
    // Custom Colors
    private let accentGreen = Color(hex: "00C853")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main Background (Match HomeView)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .contentShape(Rectangle())

                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                        
                        // Segmented Control
                        customSegmentedControl
                        
                        // Main Card
                        VStack(spacing: 24) {
                            if viewModel.authMethod == .phone {
                                phoneAuthContent
                            } else {
                                emailAuthContent
                            }
                            
                            // Forgot Password
                            if viewModel.authMethod == .email {
                                HStack {
                                    Spacer()
                                    Button("Forgot Password?") {
                                        // Handle forgot password
                                    }
                                    .font(.caption)
                                    .foregroundStyle(accentGreen)
                                }
                            }
                            
                            // Action Button
                            actionButton
                            
                            // Divider
                            HStack {
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                                Text("OR CONTINUE WITH")
                                    .font(.caption2)
                                    .foregroundStyle(Color.white.opacity(0.4))
                                    .fixedSize()
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Google Button
                            googleButton
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                        
                        // Footer Links
                        VStack(spacing: 24) {
                            Button {
                                withAnimation {
                                    viewModel.isSignUp.toggle()
                                }
                            } label: {
                                Text(viewModel.isSignUp ? "Already have an account? " : "Don't have an account? ")
                                    .foregroundStyle(Color.white.opacity(0.6)) +
                                Text(viewModel.isSignUp ? "Login" : "Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundStyle(accentGreen)
                            }
                            .font(.subheadline)
                            
                            Button {
                                viewModel.loginAnonymously()
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Guest Mode")
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .font(.footnote)
                                .foregroundStyle(Color.white.opacity(0.3))
                            }
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .onTapGesture {
                isFocused = false
            }
            .onAppear {
                isAnimating = true
                isFocused = true
            }
            .alert("Authentication Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(accentGreen)
                    )
                
                Circle()
                    .fill(accentGreen)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                    )
                    .offset(x: 2, y: 2)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text(viewModel.isSignUp ? "Create an account to get started" : "Please log in to your account")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Phone", method: .phone)
            segmentButton(title: "Email", method: .email)
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    private func segmentButton(title: String, method: AuthMethod) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.authMethod = method
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(viewModel.authMethod == method ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.authMethod == method ? Color.white.opacity(0.1) : Color.clear)
                )
        }
    }
    
    private var actionButton: some View {
        Button {
            viewModel.handleAction()
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(viewModel.actionButtonTitle)
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                        .fontWeight(.bold)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(accentGreen)
            .cornerRadius(16)
            .shadow(color: accentGreen.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isLoading)
    }
    
    private var googleButton: some View {
        Button {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else { return }
            viewModel.signInWithGoogle(rootViewController: rootViewController)
        } label: {
            HStack {
                Image(systemName: "globe") // Ideally use Google logo asset
                    .font(.body)
                Text("Google")
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var phoneAuthContent: some View {
        if !viewModel.isOTPSent {
            styledTextField(title: "Phone Number", text: $viewModel.phoneNumber, icon: "phone", keyboardType: .phonePad)
        } else {
            styledTextField(title: "SMS Code", text: $viewModel.verificationCode, icon: "key", keyboardType: .numberPad)
            
            Button("Change Number") {
                withAnimation {
                    viewModel.isOTPSent = false
                }
            }
            .font(.caption)
            .foregroundStyle(accentGreen)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    private var emailAuthContent: some View {
        styledTextField(title: "Email Address", text: $viewModel.email, icon: "envelope", keyboardType: .emailAddress)
        
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(width: 20)
            
            if showPassword {
                TextField("Password", text: $viewModel.password)
                    .foregroundStyle(.white)
                    .focused($isFocused)
            } else {
                SecureField("Password", text: $viewModel.password)
                    .foregroundStyle(.white)
                    .focused($isFocused)
            }
            
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye" : "eye.slash")
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .padding()
        .frame(height: 56)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func styledTextField(title: String, text: Binding<String>, icon: String, keyboardType: UIKeyboardType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(width: 20)
            
            TextField(title, text: text)
                .keyboardType(keyboardType)
                .foregroundStyle(.white)
                .textInputAutocapitalization(title.contains("Email") ? .never : .sentences)
                .focused($isFocused)
        }
        .padding()
        .frame(height: 56)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Helper for Hex Colors (retained)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    AuthView()
}
