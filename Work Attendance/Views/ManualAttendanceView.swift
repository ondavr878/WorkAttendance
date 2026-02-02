//
//  ManualAttendanceView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import SwiftData

struct ManualAttendanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var checkInTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var checkOutTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .colorScheme(.dark)
                    } header: {
                        Text("Session Date")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    Section {
                        DatePicker("Check In", selection: $checkInTime, displayedComponents: .hourAndMinute)
                            .colorScheme(.dark)
                        
                        DatePicker("Check Out", selection: $checkOutTime, displayedComponents: .hourAndMinute)
                            .colorScheme(.dark)
                    } header: {
                        Text("Working Hours")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    Section {
                        Button {
                            saveManualEntry()
                        } label: {
                            Text("Add Attendance")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.white)
                        }
                        .listRowBackground(Color.blue)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Past Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func saveManualEntry() {
        // Combine date and times
        let calendar = Calendar.current
        
        var checkInComponents = calendar.dateComponents([.hour, .minute], from: checkInTime)
        checkInComponents.year = calendar.component(.year, from: date)
        checkInComponents.month = calendar.component(.month, from: date)
        checkInComponents.day = calendar.component(.day, from: date)
        
        var checkOutComponents = calendar.dateComponents([.hour, .minute], from: checkOutTime)
        checkOutComponents.year = calendar.component(.year, from: date)
        checkOutComponents.month = calendar.component(.month, from: date)
        checkOutComponents.day = calendar.component(.day, from: date)
        
        let finalCheckIn = calendar.date(from: checkInComponents)
        let finalCheckOut = calendar.date(from: checkOutComponents)
        
        let newAttendance = Attendance(
            date: date,
            checkInTime: finalCheckIn,
            checkOutTime: finalCheckOut,
            checkInManual: true,
            checkOutManual: true
        )
        
        modelContext.insert(newAttendance)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving manual attendance: \(error)")
        }
    }
}
