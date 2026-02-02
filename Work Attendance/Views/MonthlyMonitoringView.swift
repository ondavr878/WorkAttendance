//
//  MonthlyMonitoringView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import SwiftData

struct MonthlyMonitoringView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MonthlyMonitoringViewModel?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Month Selector
                            monthSelector(viewModel: viewModel)
                            
                            // Statistics Cards
                            statisticsCards(viewModel: viewModel)
                            
                            // Attendance List
                            attendanceList(viewModel: viewModel)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationTitle("Monthly Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                setupViewModel()
                viewModel?.loadMonthData()
            }
        }
    }
    
    // MARK: - View Components
    
    private func monthSelector(viewModel: MonthlyMonitoringViewModel) -> some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(viewModel.monthYearText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                if !Calendar.current.isDate(viewModel.currentMonth, equalTo: Date(), toGranularity: .month) {
                    Button("Go to Current") {
                        viewModel.goToCurrentMonth()
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func statisticsCards(viewModel: MonthlyMonitoringViewModel) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Working Days
                statisticCard(
                    icon: "calendar.badge.checkmark",
                    iconColor: .blue,
                    title: "Working Days",
                    value: "\(viewModel.workingDaysCount)",
                    subtitle: "completed"
                )
                
                // Total Hours
                statisticCard(
                    icon: "clock.fill",
                    iconColor: .green,
                    title: "Total Hours",
                    value: viewModel.formattedTotalWorkedHours,
                    subtitle: "worked"
                )
            }
            
            // Average Hours
            HStack(spacing: 16) {
                statisticCard(
                    icon: "chart.bar.fill",
                    iconColor: .orange,
                    title: "Average",
                    value: viewModel.formattedAverageWorkHours,
                    subtitle: "per day"
                )
                
                // Empty space for balance
                Color.clear
            }
        }
    }
    
    private func statisticCard(icon: String, iconColor: Color, title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func attendanceList(viewModel: MonthlyMonitoringViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Records")
                .font(.headline)
                .foregroundStyle(.white)
            
            if viewModel.attendanceRecords.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.sortedRecords, id: \.id) { record in
                        AttendanceRowView(
                            attendance: record,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            Text("No records for this month")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel() {
        if viewModel == nil {
            viewModel = MonthlyMonitoringViewModel(modelContext: modelContext)
        }
    }
}

#Preview {
    MonthlyMonitoringView()
        .modelContainer(for: Attendance.self, inMemory: true)
}
