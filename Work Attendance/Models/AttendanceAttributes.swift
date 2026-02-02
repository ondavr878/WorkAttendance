//
//  AttendanceAttributes.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import ActivityKit

struct AttendanceAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes over time
        var checkInTime: Date
    }

    // Static data that doesn't change
    var locationName: String
}
