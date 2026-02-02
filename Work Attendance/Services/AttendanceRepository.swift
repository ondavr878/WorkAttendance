//
//  AttendanceRepository.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation

protocol AttendanceRepository {
    func fetchTodayAttendance() async throws -> Attendance?
    func fetchHistory(startDate: Date, endDate: Date) async throws -> [Attendance]
    func checkIn(time: Date, manual: Bool, latitude: Double, longitude: Double) async throws -> Attendance
    func checkOut(time: Date, manual: Bool) async throws -> Attendance
    func updateTime(attendance: Attendance, checkInTime: Date?, checkOutTime: Date?) async throws
    func deleteAttendance(_ attendance: Attendance) async throws
    func getAttendanceCount() async throws -> Int
}
