//
//  NotificationManager.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import UserNotifications

@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    // MARK: - Configuration
    
    /// Work start time (9:00 AM default)
    static let workStartHour: Int = 9
    static let workStartMinute: Int = 0
    
    /// Work end time (6:00 PM default)
    static let workEndHour: Int = 18
    static let workEndMinute: Int = 0
    
    // MARK: - Properties
    
    var isAuthorized: Bool = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule check-in reminder
    func scheduleCheckInReminder() {
        removeNotification(identifier: "checkInReminder")
        
        var dateComponents = DateComponents()
        dateComponents.hour = Self.workStartHour
        dateComponents.minute = Self.workStartMinute + 15 // 15 min after work start
        
        let content = UNMutableNotificationContent()
        content.title = "Work Attendance"
        content.body = "Please check in to work"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "checkInReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    /// Schedule check-out reminder
    func scheduleCheckOutReminder() {
        removeNotification(identifier: "checkOutReminder")
        
        var dateComponents = DateComponents()
        dateComponents.hour = Self.workEndHour
        dateComponents.minute = Self.workEndMinute - 15 // 15 min before work end
        
        let content = UNMutableNotificationContent()
        content.title = "Work Attendance"
        content.body = "Please check out from work"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "checkOutReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    /// Schedule incomplete session reminder
    func scheduleIncompleteSessionReminder() {
        removeNotification(identifier: "incompleteSession")
        
        var dateComponents = DateComponents()
        dateComponents.hour = Self.workEndHour + 1 // 1 hour after work end
        dateComponents.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Work Attendance"
        content.body = "Today's work session is not completed"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "incompleteSession", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    /// Schedule all standard reminders
    func scheduleAllReminders() {
        scheduleCheckInReminder()
        scheduleCheckOutReminder()
        scheduleIncompleteSessionReminder()
    }
    
    // MARK: - Cancel Notifications
    
    func removeNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelCheckOutReminderForToday() {
        removeNotification(identifier: "checkOutReminder")
    }
    
    func cancelIncompleteSessionReminderForToday() {
        removeNotification(identifier: "incompleteSession")
    }
    
    /// Send instant notification for location saved successfully
    func sendLocationSavedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Work Attendance"
        content.body = "Office location saved successfully! ✅"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "locationSaved", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}
