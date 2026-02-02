//
//  RemoteAttendanceRepository.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct AttendanceDTO: Codable {
    var id: String
    var date: Date
    var checkInTime: Date?
    var checkOutTime: Date?
    var checkInManual: Bool
    var checkOutManual: Bool
    var latitude: Double?
    var longitude: Double?
    
    init(from attendance: Attendance) {
        self.id = attendance.id.uuidString
        self.date = attendance.date
        self.checkInTime = attendance.checkInTime
        self.checkOutTime = attendance.checkOutTime
        self.checkInManual = attendance.checkInManual
        self.checkOutManual = attendance.checkOutManual
        self.latitude = attendance.latitude
        self.longitude = attendance.longitude
    }
    
    func toDomain() -> Attendance {
        return Attendance(
            id: UUID(uuidString: id) ?? UUID(),
            date: date,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            checkInManual: checkInManual,
            checkOutManual: checkOutManual,
            latitude: latitude,
            longitude: longitude
        )
    }
}

final class RemoteAttendanceRepository: AttendanceRepository {
    private let db = Firestore.firestore()
    private let authService: AuthService
    
    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private func getCollection() throws -> CollectionReference {
        guard let uid = userId else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        return db.collection("users").document(uid).collection("attendance")
    }
    
    private func ensureAuthenticated() async throws {
        if Auth.auth().currentUser == nil {
            try await authService.signInAnonymously()
        }
    }
    
    func fetchTodayAttendance() async throws -> Attendance? {
        try await ensureAuthenticated()
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let snapshot = try await getCollection()
            .whereField("date", isGreaterThanOrEqualTo: today)
            .whereField("date", isLessThan: tomorrow)
            .limit(to: 1)
            .getDocuments()
            
        guard let document = snapshot.documents.first else { return nil }
        
        let dto = try document.data(as: AttendanceDTO.self)
        return dto.toDomain()
    }
    
    func fetchHistory(startDate: Date, endDate: Date) async throws -> [Attendance] {
        try await ensureAuthenticated()
        
        let snapshot = try await getCollection()
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date", descending: true)
            .getDocuments()
            
        return try snapshot.documents.map { doc in
            let dto = try doc.data(as: AttendanceDTO.self)
            return dto.toDomain()
        }
    }
    
    func checkIn(time: Date, manual: Bool, latitude: Double, longitude: Double) async throws -> Attendance {
        try await ensureAuthenticated()
        
        // Check for existing first to avoid duplicates if called multiple times rapidly
        if let existing = try await fetchTodayAttendance() {
            return try await updateExistingCheckIn(existing, time: time, manual: manual, latitude: latitude, longitude: longitude)
        }
        
        // Save/Update User Profile
        try await saveUserProfile()
        
        let newAttendance = Attendance(
            date: Date(),
            checkInTime: time,
            checkInManual: manual,
            latitude: latitude,
            longitude: longitude
        )
        
        let dto = AttendanceDTO(from: newAttendance)
        try getCollection().document(dto.id).setData(from: dto)
        return newAttendance
    }
    
    private func updateExistingCheckIn(_ attendance: Attendance, time: Date, manual: Bool, latitude: Double, longitude: Double) async throws -> Attendance {
        attendance.checkInTime = time
        attendance.checkInManual = manual
        attendance.latitude = latitude
        attendance.longitude = longitude
        
        let dto = AttendanceDTO(from: attendance)
        try getCollection().document(dto.id).setData(from: dto)
        return attendance
    }
    
    func checkOut(time: Date, manual: Bool) async throws -> Attendance {
        try await ensureAuthenticated()
        
        guard let today = try await fetchTodayAttendance() else {
             throw NSError(domain: "Attendance", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active check-in found for today"])
        }
        
        today.checkOutTime = time
        today.checkOutManual = manual
        
        let dto = AttendanceDTO(from: today)
        try getCollection().document(dto.id).setData(from: dto)
        return today
    }
    
    func updateTime(attendance: Attendance, checkInTime: Date?, checkOutTime: Date?) async throws {
        try await ensureAuthenticated()
        
        if let checkInTime {
            attendance.checkInTime = checkInTime
            attendance.checkInManual = true
        }
        if let checkOutTime {
            attendance.checkOutTime = checkOutTime
            attendance.checkOutManual = true
        }
        
        let dto = AttendanceDTO(from: attendance)
        try getCollection().document(dto.id).setData(from: dto)
    }
    
    func deleteAttendance(_ attendance: Attendance) async throws {
        try await ensureAuthenticated()
        try await getCollection().document(attendance.id.uuidString).delete()
    }
    
    func getAttendanceCount() async throws -> Int {
        try await ensureAuthenticated()
        let snapshot = try await getCollection().count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
    
    private func saveUserProfile() async throws {
        guard let uid = userId else { return }
        
        var data: [String: Any] = [
            "name": AuthManager.shared.userName,
            "lastActive": FieldValue.serverTimestamp(),
            "isAnonymous": AuthManager.shared.isAnonymous
        ]
        
        if let email = AuthManager.shared.userEmail {
            data["email"] = email
        }
        
        if let phone = AuthManager.shared.userPhone {
            data["phone"] = phone
        }
        
        try await db.collection("users").document(uid).setData(data, merge: true)
    }
}
