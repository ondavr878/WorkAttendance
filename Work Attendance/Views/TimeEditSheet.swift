//
//  TimeEditSheet.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI

struct TimeEditSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AttendanceViewModel
    
    @State private var selectedTime: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: viewModel.editingCheckIn ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(viewModel.editingCheckIn ? .green : .red)
                        
                        Text(viewModel.editingCheckIn ? "Edit Check In Time" : "Edit Check Out Time")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        Text("This will be marked as manual entry")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(.top, 20)
                    
                    // Date Picker
                    DatePicker(
                        "",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    
                    Spacer()
                    
                    // Save Button
                    Button {
                        viewModel.updateTime(selectedTime)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                            )
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
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
        .onAppear {
            if viewModel.editingCheckIn {
                selectedTime = viewModel.todayAttendance?.checkInTime ?? Date()
            } else {
                selectedTime = viewModel.todayAttendance?.checkOutTime ?? Date()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
