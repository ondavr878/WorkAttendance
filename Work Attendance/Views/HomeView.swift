//
//  HomeView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AttendanceViewModel?
    @State private var locationManager = LocationManager()
    @State private var notificationManager = NotificationManager()
    @State private var showSettings = false
    @State private var showStats = false
    
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
                        VStack(spacing: 24) {
                            // Date Header
                            dateHeaderView
                            
                            // Status Card
                            statusCard(viewModel: viewModel)
                            
                            // Time Display
                            timeDisplayCard(viewModel: viewModel)
                            
                            // Action Buttons
                            actionButtons(viewModel: viewModel)
                            
                            // Stats Button
                            statsButton
                            
                            // Location Status
                            locationStatusCard(viewModel: viewModel)
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                setupViewModel()
                Task {
                    await viewModel?.loadTodayAttendance()
                }
            }
            .sheet(isPresented: $showSettings) {
                if let viewModel = viewModel {
                    SettingsView(locationManager: locationManager, notificationManager: notificationManager)
                        .environment(viewModel)
                        .onDisappear {
                            // Only reload if still authenticated (avoids auto-login loop on sign out)
                            if AuthManager.shared.isAuthenticated {
                                viewModel.reloadDataSource()
                            }
                        }
                }
            }
            .sheet(isPresented: $showStats) {
                if let viewModel = viewModel {
                    StatsView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showTimeEditSheet ?? false },
                set: { viewModel?.showTimeEditSheet = $0 }
            )) {
                if let viewModel = viewModel {
                    TimeEditSheet(viewModel: viewModel)
                }
            }
            .alert("Location Error", isPresented: Binding(
                get: { viewModel?.showLocationAlert ?? false },
                set: { viewModel?.showLocationAlert = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You are \(Int(viewModel?.distanceFromOffice ?? 0))m away from the office. Please move within \(Int(locationManager.allowedRadius))m to check in.")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel?.showError ?? false },
                set: { viewModel?.showError = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel?.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - View Components
    
    private var dateHeaderView: some View {
        VStack(spacing: 4) {
            Text("Hello, \(AuthManager.shared.userName)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(currentDateFormatted)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
            
            Text(currentDayFormatted)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private func statusCard(viewModel: AttendanceViewModel) -> some View {
        VStack(spacing: 12) {
            Image(systemName: statusIcon(viewModel: viewModel))
                .font(.system(size: 48))
                .foregroundStyle(statusColor(viewModel: viewModel))
            
            Text(viewModel.statusText)
                .font(.headline)
                .foregroundStyle(.white)
            
            if let attendance = viewModel.todayAttendance, attendance.isComplete {
                Text("Total: \(viewModel.totalWorkTimeText)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private func timeDisplayCard(viewModel: AttendanceViewModel) -> some View {
        HStack(spacing: 20) {
            // Check In Time
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                    Text("Check In")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Text(viewModel.checkInTimeText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                if viewModel.todayAttendance?.checkInManual == true {
                    Text("Manual")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .onTapGesture {
                if viewModel.todayAttendance?.checkInTime != nil {
                    viewModel.editCheckInTime()
                }
            }
            
            // Check Out Time
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.red)
                    Text("Check Out")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Text(viewModel.checkOutTimeText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                if viewModel.todayAttendance?.checkOutManual == true {
                    Text("Manual")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .onTapGesture {
                if viewModel.todayAttendance?.checkOutTime != nil {
                    viewModel.editCheckOutTime()
                }
            }
        }
    }
    
    private func actionButtons(viewModel: AttendanceViewModel) -> some View {
        VStack(spacing: 16) {
            // Check In Button
            Button {
                Task {
                    await viewModel.checkIn()
                }
            } label: {
                HStack {
                    if viewModel.isLoading && viewModel.canCheckIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Check In")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(viewModel.canCheckIn ? 
                              LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                )
            }
            .disabled(!viewModel.canCheckIn || viewModel.isLoading)
            
            // Check Out Button
            Button {
                viewModel.checkOut()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Check Out")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(viewModel.canCheckOut ? 
                              LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                )
            }
            .disabled(!viewModel.canCheckOut)
        }
    }
    
    private var statsButton: some View {
        Button {
            showStats = true
        } label: {
            HStack {
                Image(systemName: "chart.bar.fill")
                Text("View Statistics")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func locationStatusCard(viewModel: AttendanceViewModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash.fill")
                .foregroundStyle(locationManager.isAuthorized ? .green : .orange)
            
            Text(viewModel.locationStatus)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            if locationManager.needsPermission {
                Button("Enable") {
                    viewModel.requestLocationPermission()
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Helpers
    
    private func setupViewModel() {
        if viewModel == nil {
            viewModel = AttendanceViewModel(
                modelContext: modelContext,
                locationManager: locationManager,
                notificationManager: notificationManager
            )
        }
    }
    
    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var currentDayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    private func statusIcon(viewModel: AttendanceViewModel) -> String {
        guard let attendance = viewModel.todayAttendance else {
            return "clock.badge.questionmark"
        }
        
        if attendance.isComplete {
            return "checkmark.circle.fill"
        } else if attendance.hasCheckedIn {
            return "clock.fill"
        } else {
            return "clock.badge.questionmark"
        }
    }
    
    private func statusColor(viewModel: AttendanceViewModel) -> Color {
        guard let attendance = viewModel.todayAttendance else {
            return .gray
        }
        
        if attendance.isComplete {
            return .green
        } else if attendance.hasCheckedIn {
            return .orange
        } else {
            return .gray
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Attendance.self, inMemory: true)
}
