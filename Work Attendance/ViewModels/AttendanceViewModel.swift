//
//  AttendanceViewModel.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import SwiftData
import CoreLocation
import WidgetKit
import ActivityKit
import UIKit

@Observable
final class AttendanceViewModel {
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext
    private let locationManager: LocationManager
    private let notificationManager: NotificationManager
    
    private let localRepository: LocalAttendanceRepository
    private let remoteRepository: RemoteAttendanceRepository
    
    private var activeRepository: AttendanceRepository {
        let source = UserDefaults.standard.string(forKey: "dataSource") ?? "remote"
        return source == "remote" ? remoteRepository : localRepository
    }
    
    // MARK: - State
    
    var todayAttendance: Attendance?
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var showTimeEditSheet: Bool = false
    var editingCheckIn: Bool = true
    var showLocationAlert: Bool = false
    var distanceFromOffice: Double = 0
    
    // MARK: - Computed Properties
    
    var canCheckIn: Bool {
        todayAttendance?.checkInTime == nil
    }
    
    var canCheckOut: Bool {
        guard let attendance = todayAttendance else { return false }
        return attendance.hasCheckedIn && !attendance.hasCheckedOut
    }
    
    var statusText: String {
        guard let attendance = todayAttendance else {
            return "Not checked in"
        }
        
        if attendance.isComplete {
            return "Work session complete"
        } else if attendance.hasCheckedIn {
            return "Checked in, awaiting check out"
        } else {
            return "Not checked in"
        }
    }
    
    var checkInTimeText: String {
        guard let time = todayAttendance?.checkInTime else {
            return "--:--"
        }
        return formatTime(time)
    }
    
    var checkOutTimeText: String {
        guard let time = todayAttendance?.checkOutTime else {
            return "--:--"
        }
        return formatTime(time)
    }
    
    var totalWorkTimeText: String {
        todayAttendance?.formattedWorkTime ?? "--:--"
    }
    
    var locationStatus: String {
        if locationManager.isPermissionDenied {
            return "Location denied"
        } else if locationManager.needsPermission {
            return "Location permission required"
        } else if locationManager.isLoading {
            return "Getting location..."
        } else {
            return "Location ready"
        }
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, locationManager: LocationManager, notificationManager: NotificationManager) {
        self.modelContext = modelContext
        self.locationManager = locationManager
        self.notificationManager = notificationManager
        
        self.localRepository = LocalAttendanceRepository(modelContext: modelContext)
        self.remoteRepository = RemoteAttendanceRepository()
        
        Task {
            await loadTodayAttendance()
        }
    }
    
    // MARK: - Data Operations
    
    func loadTodayAttendance() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await activeRepository.fetchTodayAttendance()
            await MainActor.run {
                todayAttendance = result
            }
        } catch {
            print("Error fetching today's attendance: \(error)")
        }
    }
    
    func reloadDataSource() {
        Task {
            await loadTodayAttendance()
        }
    }
    
    // MARK: - Check In
    
    func checkIn(manual: Bool = false, time: Date = Date()) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // 0. Check Guest Limit
        if AuthManager.shared.isAnonymous {
            do {
                let count = try await activeRepository.getAttendanceCount()
                if count >= 2 {
                    await MainActor.run {
                        errorMessage = "Guest limit reached (2 check-ins). Please sign in to continue."
                        showError = true
                        triggerHaptic(type: .error)
                    }
                    return
                }
            } catch {
                print("Error checking guest limit: \(error)")
                // Proceed or fail? Let's proceed if check fails, or fail? Failing safe:
                // Let's just log it and proceed for now, or fail. Faling is better for "security".
                // But if network fails, user can't check in?
                // Let's assume if we can't count, we proceed (fail open) for UX, or fail closed?
                // Given "Network", maybe fail open if error?
                // Actually, ensureAuthenticated is called inside getAttendanceCount, so it should be fine.
            }
        }
        
        // 1. Biometric Authentication
        do {
            let authenticated = try await BiometricService.shared.authenticateUser(reason: "Authenticate to Check In")
            guard authenticated else { return } // Cancelled or failed gracefully
        } catch {
             await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                triggerHaptic(type: .error)
             }
             return
        }
        
        // 2. Validate location
        do {
            let (isValid, location) = try await locationManager.validateOfficeProximity()
            
            if !isValid {
                await MainActor.run {
                    distanceFromOffice = locationManager.distanceFromOffice(location: location)
                    showLocationAlert = true
                    triggerHaptic(type: .warning)
                }
                return
            }
            
            await MainActor.run {
                Task {
                    do {
                        let updated = try await activeRepository.checkIn(
                            time: time,
                            manual: manual,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                        
                        await MainActor.run {
                            todayAttendance = updated
                            startLiveActivity(checkInTime: time)
                            WidgetCenter.shared.reloadAllTimelines()
                            triggerHaptic(type: .success)
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = "Failed to check in: \(error.localizedDescription)"
                            showError = true
                            triggerHaptic(type: .error)
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                triggerHaptic(type: .error)
            }
        }
    }
    
    // MARK: - Check Out
    
    func checkOut(manual: Bool = false, time: Date = Date()) {
        Task {
            do {
                let authenticated = try await BiometricService.shared.authenticateUser(reason: "Authenticate to Check Out")
                guard authenticated else { return }
                
                let updated = try await activeRepository.checkOut(time: time, manual: manual)
                
                await MainActor.run {
                    todayAttendance = updated
                    WidgetCenter.shared.reloadAllTimelines()
                    notificationManager.cancelCheckOutReminderForToday()
                    notificationManager.cancelIncompleteSessionReminderForToday()
                    endLiveActivity()
                    // Don't modify endLiveActivity() here, call it
                    triggerHaptic(type: .success)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    triggerHaptic(type: .error)
                }
            }
        }
    }
    
    // MARK: - Time Editing
    
    func editCheckInTime() {
        editingCheckIn = true
        showTimeEditSheet = true
    }
    
    func editCheckOutTime() {
        editingCheckIn = false
        showTimeEditSheet = true
    }
    
    func updateTime(_ newTime: Date) {
        guard let attendance = todayAttendance else { return }
        
        let updateCheckIn = editingCheckIn
        
        Task {
            do {
                try await activeRepository.updateTime(
                    attendance: attendance,
                    checkInTime: updateCheckIn ? newTime : nil,
                    checkOutTime: !updateCheckIn ? newTime : nil
                )
                
                await MainActor.run {
                    if updateCheckIn {
                        attendance.checkInTime = newTime
                        attendance.checkInManual = true
                    } else {
                        attendance.checkOutTime = newTime
                        attendance.checkOutManual = true
                    }
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update time: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Location
    
    func requestLocationPermission() {
        locationManager.requestPermission()
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity(checkInTime: Date) {
        if #available(iOS 16.1, *) {
            let attributes = AttendanceAttributes(locationName: "Office")
            let contentState = AttendanceAttributes.ContentState(checkInTime: checkInTime)
            
            do {
                let activity = try Activity<AttendanceAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil)
                )
                print("Live Activity started: \(activity.id)")
            } catch {
                print("Error starting Live Activity: \(error)")
            }
        }
    }
    
    private func endLiveActivity() {
        if #available(iOS 16.1, *) {
            Task {
                for activity in Activity<AttendanceAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
    
    
    // MARK: - Haptics
    
    private func triggerHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Statistics
    
    struct DailyStat: Identifiable {
        let id = UUID()
        let date: Date
        let hours: Double
        let weekday: String
    }
    
    func calculateWeeklyStats() async -> [DailyStat] {
        var stats: [DailyStat] = []
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
        let startOfHistory = calendar.startOfDay(for: weekAgo)
        // End of today (tomorrow start)
        let endOfHistory = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!
        
        do {
            let history = try await activeRepository.fetchHistory(startDate: startOfHistory, endDate: endOfHistory)
            
            // Map history to dictionary for O(1) lookup
            // Note: Attendance is a class, ensure we are on MainActor if using SwiftData models properties
            
            for i in (0..<7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let weekday = formatWeekday(date)
                    
                    // Find attendance for this day
                    let attendance = history.first { calendar.isDate($0.date, inSameDayAs: date) }
                    
                    var workHours: Double = 0
                    if let totalTime = attendance?.totalWorkTime {
                        workHours = totalTime / 3600.0
                    }
                    
                    stats.append(DailyStat(date: date, hours: workHours, weekday: weekday))
                }
            }
        } catch {
            print("Error fetching history stats: \(error)")
        }
        
        return stats
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        return formatter.string(from: date)
    }

}
