//
//  SettingsView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var locationManager: LocationManager
    var notificationManager: NotificationManager
    var appPreferences = AppPreferences.shared
    
    @State private var showOfficeMap = false
    @State private var showManualEntry = false
    @State private var showDeleteAlert = false
    
    @AppStorage("dataSource") private var dataSource: String = "local"
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(AuthManager.shared.userName.prefix(1).uppercased())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AuthManager.shared.userName)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(AuthManager.shared.isAnonymous ? "Guest Account" : "Registered User")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Profile")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section {
                    Toggle(isOn: Bindable(appPreferences).isPremium) {
                        VStack(alignment: .leading) {
                            Text("Premium Plan")
                                .foregroundStyle(.white)
                            Text("Access special features")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .tint(.orange)
                } header: {
                    Text("User Status")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section {
                    Picker("Storage Location", selection: $dataSource) {
                        Text("Local (Device Only)").tag("local")
                        Text("Cloud (Firebase)").tag("remote")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Data Storage")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section {
                    Button {
                        showOfficeMap = true
                    } label: {
                        HStack {
                            Label("Office Location", systemImage: "map.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .foregroundStyle(.white)
                    }
                } header: {
                    Text("Configuration")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                if appPreferences.isPremium {
                    Section {
                        Button {
                            showManualEntry = true
                        } label: {
                            HStack {
                                Label("Add Past Attendance", systemImage: "calendar.badge.plus")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .foregroundStyle(.white)
                        }
                    } header: {
                        Text("Premium Tools")
                            .foregroundStyle(.orange.opacity(0.8))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                    }
                } header: {
                    Text("Maintenance")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section {
                    Button {
                        try? AuthManager.shared.signOut()
                        dismiss()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Account")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.15, green: 0.15, blue: 0.25)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showOfficeMap) {
                OfficeSettingsView(locationManager: locationManager, notificationManager: notificationManager)
            }
            .sheet(isPresented: $showManualEntry) {
                ManualAttendanceView()
            }
            .alert("Clear All Data", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("This will permanently delete all attendance records and reset settings. This action cannot be undone.")
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext

    private func clearCache() {
        // Delete all SwiftData records
        do {
            try modelContext.delete(model: Attendance.self)
            try modelContext.save()
            
            // Clear UserDefaults (except premium status if you want to keep it, but usually clear cache means everything)
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            // Success notification
            notificationManager.sendLocationSavedNotification() // Reusing the notification system to show success
            
            dismiss()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}
