//
//  ContentView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @State private var selectedTab: Int = 0
    @State private var authManager = AuthManager.shared
    
    var body: some View {
        if authManager.isAuthenticated {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                MonthlyMonitoringView()
                    .tabItem {
                        Label("Reports", systemImage: "chart.bar.fill")
                    }
                    .tag(1)
            }
            .tint(.blue)
        } else {
            AuthView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Attendance.self, inMemory: true)
}
