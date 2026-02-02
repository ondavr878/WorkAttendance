//
//  AuthManager.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import FirebaseAuth
import Observation

@Observable
final class AuthManager {
    static let shared = AuthManager()
    
    var user: User?
    var isAuthenticated: Bool = false
    
    var isAnonymous: Bool {
        user?.isAnonymous ?? false
    }
    
    var userEmail: String? {
        user?.email
    }
    
    var userPhone: String? {
        user?.phoneNumber
    }
    
    var userName: String {
        if let name = user?.displayName, !name.isEmpty {
            return name
        }
        if let email = user?.email, !email.isEmpty {
            return email
        }
        if let phone = user?.phoneNumber, !phone.isEmpty {
            return phone
        }
        return "Guest"
    }
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    private init() {
        monitorAuthState()
    }
    
    func monitorAuthState() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
