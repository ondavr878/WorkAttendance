//
//  Work_AttendanceApp.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn



@main
struct Work_AttendanceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Attendance.self,
        ])
        
        // Use App Group container for shared storage
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourname.WorkAttendance")
        let config: ModelConfiguration
        
        if let appGroupURL = appGroupURL {
            let sqliteURL = appGroupURL.appendingPathComponent("WorkAttendance.sqlite")
            config = ModelConfiguration(schema: schema, url: sqliteURL)
        } else {
            // Fallback (mostly for previews if App Group fails, though it shouldn't in a real app)
            print("WARNING: Could not find App Group container. Using default storage.")
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupNotifications()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupNotifications() {
        Task {
            let granted = await notificationManager.requestPermission()
            if granted {
                notificationManager.scheduleAllReminders()
            }
        }
    }
}
