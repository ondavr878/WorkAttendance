//
//  MonthlyMonitoringViewModel.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import SwiftData

@Observable
final class MonthlyMonitoringViewModel {
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext
    
    // MARK: - State
    
    var currentMonth: Date = Date()
    var attendanceRecords: [Attendance] = []
    var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var workingDaysCount: Int {
        attendanceRecords.filter { $0.isComplete }.count
    }
    
    var totalWorkedSeconds: TimeInterval {
        attendanceRecords.compactMap { $0.totalWorkTime }.reduce(0, +)
    }
    
    var totalWorkedHours: Double {
        totalWorkedSeconds / 3600
    }
    
    var formattedTotalWorkedHours: String {
        let hours = Int(totalWorkedSeconds) / 3600
        let minutes = (Int(totalWorkedSeconds) % 3600) / 60
        return String(format: "%d h %02d min", hours, minutes)
    }
    
    var averageWorkHours: Double {
        guard workingDaysCount > 0 else { return 0 }
        return totalWorkedHours / Double(workingDaysCount)
    }
    
    var formattedAverageWorkHours: String {
        let totalSeconds = averageWorkHours * 3600
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        return String(format: "%d h %02d min", hours, minutes)
    }
    
    var sortedRecords: [Attendance] {
        attendanceRecords.sorted { $0.date > $1.date }
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadMonthData()
    }
    
    // MARK: - Data Operations
    
    func loadMonthData() {
        isLoading = true
        
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        let endOfMonthPlusOne = calendar.date(byAdding: .day, value: 1, to: endOfMonth)!
        
        let descriptor = FetchDescriptor<Attendance>(
            predicate: #Predicate { attendance in
                attendance.date >= startOfMonth && attendance.date < endOfMonthPlusOne
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            attendanceRecords = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching monthly data: \(error)")
            attendanceRecords = []
        }
        
        isLoading = false
    }
    
    // MARK: - Navigation
    
    func goToPreviousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        loadMonthData()
    }
    
    func goToNextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        loadMonthData()
    }
    
    func goToCurrentMonth() {
        currentMonth = Date()
        loadMonthData()
    }
    
    // MARK: - Helpers
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
