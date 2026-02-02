//
//  AttendanceRowView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI

struct AttendanceRowView: View {
    
    let attendance: Attendance
    let viewModel: MonthlyMonitoringViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Date indicator
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(dayName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(width: 48)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 40)
            
            // Time Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 16) {
                    // Check In
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        Text(viewModel.formatTime(attendance.checkInTime))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        
//                        if attendance.checkInManual {
//                            Image(systemName: "pencil.circle.fill")
//                                .font(.caption2)
//                                .foregroundStyle(.orange)
//                        }
                    }
                    
                    // Check Out
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        
                        Text(viewModel.formatTime(attendance.checkOutTime))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        
//                        if attendance.checkOutManual {
//                            Image(systemName: "pencil.circle.fill")
//                                .font(.caption2)
//                                .foregroundStyle(.orange)
//                        }
                    }
                }
            }
            
            Spacer()
            
            // Total Time
            VStack(alignment: .trailing, spacing: 4) {
                Text(attendance.formattedWorkTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(attendance.isComplete ? .green : .gray)
                
                if !attendance.isComplete {
                    Text("Incomplete")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusBorderColor, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: attendance.date)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: attendance.date)
    }
    
    private var statusBorderColor: Color {
        if attendance.isComplete {
            return .green.opacity(0.3)
        } else if attendance.hasCheckedIn {
            return .orange.opacity(0.3)
        } else {
            return Color.white.opacity(0.1)
        }
    }
}
