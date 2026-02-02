//
//  AppPreferences.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import Observation

@Observable
final class AppPreferences {
    private let userDefaults = UserDefaults.standard
    private let premiumKey = "is_premium_user"
    
    var isPremium: Bool {
        didSet {
            userDefaults.set(isPremium, forKey: premiumKey)
        }
    }
    
    static let shared = AppPreferences()
    
    private init() {
        self.isPremium = userDefaults.bool(forKey: premiumKey)
    }
}
