//
//  Attendance.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import SwiftData

@Model
final class Attendance {
    var id: UUID
    var userId: String?
    var date: Date
    var checkInTime: Date?
    var checkOutTime: Date?
    var checkInManual: Bool
    var checkOutManual: Bool
    var latitude: Double?
    var longitude: Double?
    
    init(
        id: UUID = UUID(),
        userId: String? = nil,
        date: Date = Date(),
        checkInTime: Date? = nil,
        checkOutTime: Date? = nil,
        checkInManual: Bool = false,
        checkOutManual: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: date)
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.checkInManual = checkInManual
        self.checkOutManual = checkOutManual
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Computed total work time in seconds
    var totalWorkTime: TimeInterval? {
        guard let checkIn = checkInTime, let checkOut = checkOutTime else {
            return nil
        }
        return checkOut.timeIntervalSince(checkIn)
    }
    
    /// Formatted total work time as HH:MM
    var formattedWorkTime: String {
        guard let total = totalWorkTime else { return "--:--" }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    /// Check if this attendance is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Check if check-in is done
    var hasCheckedIn: Bool {
        checkInTime != nil
    }
    
    /// Check if check-out is done
    var hasCheckedOut: Bool {
        checkOutTime != nil
    }
    
    /// Check if the work session is complete
    var isComplete: Bool {
        hasCheckedIn && hasCheckedOut
    }
}
