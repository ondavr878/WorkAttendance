//
//  LocalAttendanceRepository.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import SwiftData
import FirebaseAuth

final class LocalAttendanceRepository: AttendanceRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    @MainActor
    func fetchTodayAttendance() async throws -> Attendance? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let userId = AuthManager.shared.user?.uid
        
        // If no user ID, we might return nil or handle as guest. 
        // For security, if no user ID, assume no data or guest data.
        
        let descriptor = FetchDescriptor<Attendance>(
            predicate: #Predicate { attendance in
                attendance.date >= today && attendance.date < tomorrow && attendance.userId == userId
            }
        )
        
        return try modelContext.fetch(descriptor).first
    }
    
    @MainActor
    func fetchHistory(startDate: Date, endDate: Date) async throws -> [Attendance] {
        let userId = AuthManager.shared.user?.uid
        
        let descriptor = FetchDescriptor<Attendance>(
            predicate: #Predicate { attendance in
                attendance.date >= startDate && attendance.date <= endDate && attendance.userId == userId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    @MainActor
    func checkIn(time: Date, manual: Bool, latitude: Double, longitude: Double) async throws -> Attendance {
        // Check if exists
        if let existing = try await fetchTodayAttendance() {
            existing.checkInTime = time
            existing.checkInManual = manual
            existing.latitude = latitude
            existing.longitude = longitude
            try modelContext.save()
            return existing
        } else {
            let newAttendance = Attendance(
                userId: AuthManager.shared.user?.uid,
                date: Date(),
                checkInTime: time,
                checkInManual: manual,
                latitude: latitude,
                longitude: longitude
            )
            modelContext.insert(newAttendance)
            try modelContext.save()
            return newAttendance
        }
    }
    
    @MainActor
    func checkOut(time: Date, manual: Bool) async throws -> Attendance {
        guard let today = try await fetchTodayAttendance() else {
            throw AttendanceError.notFound
        }
        
        today.checkOutTime = time
        today.checkOutManual = manual
        try modelContext.save()
        return today
    }
    
    @MainActor
    func updateTime(attendance: Attendance, checkInTime: Date?, checkOutTime: Date?) async throws {
        if let checkInTime {
            attendance.checkInTime = checkInTime
            attendance.checkInManual = true
        }
        if let checkOutTime {
            attendance.checkOutTime = checkOutTime
            attendance.checkOutManual = true
        }
        try modelContext.save()
    }
    
    @MainActor
    func deleteAttendance(_ attendance: Attendance) async throws {
        modelContext.delete(attendance)
        try modelContext.save()
    }
    
    func getAttendanceCount() async throws -> Int {
        let userId = AuthManager.shared.user?.uid
        let descriptor = FetchDescriptor<Attendance>(
            predicate: #Predicate { attendance in
                attendance.userId == userId
            }
        )
        return try modelContext.fetchCount(descriptor)
    }
}

enum AttendanceError: Error {
    case notFound
}
