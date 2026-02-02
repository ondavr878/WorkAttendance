//
//  AttendanceWidget.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import WidgetKit
import SwiftUI
import SwiftData

struct AttendanceEntry: TimelineEntry {
    let date: Date
    let state: AttendanceState
    let checkInTime: Date?
    let checkOutTime: Date?
    let workDuration: String
}

enum AttendanceState {
    case notStarted
    case checkedIn
    case completed
}

struct AttendanceProvider: TimelineProvider {
    
    @MainActor
    func placeholder(in context: Context) -> AttendanceEntry {
        AttendanceEntry(date: Date(), state: .notStarted, checkInTime: nil, checkOutTime: nil, workDuration: "0h 0m")
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (AttendanceEntry) -> ()) {
        let entry = fetchAttendance(for: Date())
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<AttendanceEntry>) -> ()) {
        let entry = fetchAttendance(for: Date())
        
        // Refresh every 10 minutes as a fallback, but relying on App to reloadTimeline
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    @MainActor
    private func fetchAttendance(for date: Date) -> AttendanceEntry {
        let schema = Schema([Attendance.self])
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourname.WorkAttendance")
        
        let config: ModelConfiguration
        if let appGroupURL = appGroupURL {
            let sqliteURL = appGroupURL.appendingPathComponent("WorkAttendance.sqlite")
            config = ModelConfiguration(schema: schema, url: sqliteURL)
        } else {
             config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            
            let today = Calendar.current.startOfDay(for: date)
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            
            let descriptor = FetchDescriptor<Attendance>(
                predicate: #Predicate { attendance in
                    attendance.date >= today && attendance.date < tomorrow
                }
            )
            
            let results = try context.fetch(descriptor)
            
            if let attendance = results.first {
                let state: AttendanceState
                if attendance.isComplete {
                    state = .completed
                } else if attendance.hasCheckedIn {
                    state = .checkedIn
                } else {
                    state = .notStarted // Should ideally not exist if record exists, but possible if created without checkin
                }
                
                return AttendanceEntry(
                    date: date,
                    state: state,
                    checkInTime: attendance.checkInTime,
                    checkOutTime: attendance.checkOutTime,
                    workDuration: attendance.formattedWorkTime
                )
            } else {
                return AttendanceEntry(date: date, state: .notStarted, checkInTime: nil, checkOutTime: nil, workDuration: "0h 0m")
            }
            
        } catch {
            print("Widget Data Fetch Error: \(error)")
            return AttendanceEntry(date: date, state: .notStarted, checkInTime: nil, checkOutTime: nil, workDuration: "Error")
        }
    }
}

struct AttendanceWidgetEntryView : View {
    var entry: AttendanceProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Background
            if entry.state == .checkedIn {
                LinearGradient(colors: [Color(hex: "34C759"), Color(hex: "30B350")], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Color(UIColor.systemBackground)
            }
            
            VStack(alignment: .leading) {
                
                // Header
                HStack {
                    Image(systemName: iconName)
                        .font(.headline)
                        .foregroundStyle(entry.state == .checkedIn ? .white : .blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(entry.state == .checkedIn ? .white.opacity(0.2) : .blue.opacity(0.1))
                        )
                    
                    Spacer()
                    
                    if entry.state == .checkedIn {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.white))
                            .foregroundStyle(Color(hex: "34C759"))
                    }
                }
                
                Spacer()
                
                // Content
                contentView
            }
            .padding()
        }
        .containerBackground(for: .widget) {
             if entry.state == .checkedIn {
                 LinearGradient(colors: [Color(hex: "34C759"), Color(hex: "30B350")], startPoint: .topLeading, endPoint: .bottomTrailing)
             } else {
                 Color(UIColor.systemBackground)
             }
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        switch entry.state {
        case .notStarted:
            VStack(alignment: .leading, spacing: 4) {
                Text("Good Morning")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Not Checked In")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
        case .checkedIn:
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Check In")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    if let checkIn = entry.checkInTime {
                        Text(checkIn, style: .time)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
                
                HStack(spacing: 6) {
                   Image(systemName: "timer")
                       .font(.caption)
                   if let checkIn = entry.checkInTime {
                       Text(checkIn, style: .timer)
                           .font(.system(.body, design: .monospaced))
                   }
                }
                .foregroundStyle(.white)
                .fontWeight(.medium)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Capsule().fill(.black.opacity(0.15)))
            }
            
        case .completed:
            VStack(alignment: .leading, spacing: 4) {
                Text("Session Complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.workDuration)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("worked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    var iconName: String {
        switch entry.state {
        case .notStarted: return "location.slash.circle.fill"
        case .checkedIn: return "figure.walk.arrival"
        case .completed: return "checkmark.seal.fill"
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@main
struct AttendanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        AttendanceWidget()
        AttendanceActivityWidget()
    }
}

struct AttendanceWidget: Widget {
    let kind: String = "AttendanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AttendanceProvider()) { entry in
            AttendanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Work Attendance")
        .description("Track your work status and hours.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct AttendanceActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AttendanceAttributes.self) { context in
            // Lock Screen / Banner UI
            HStack {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(Color(hex: "34C759")))
                
                VStack(alignment: .leading) {
                    Text("Work Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Active")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(context.state.checkInTime, style: .timer)
                        .font(.title2)
                        .monospacedDigit()
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "34C759"))
                }
            }
            .padding()
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "figure.run")
                            .foregroundStyle(Color(hex: "34C759"))
                        Text("Work")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.checkInTime, style: .timer)
                        .font(.title2)
                        .monospacedDigit()
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "34C759"))
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Spacer()
                        Label(context.attributes.locationName, systemImage: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                
            } compactLeading: {
                Image(systemName: "figure.run")
                    .foregroundStyle(Color(hex: "34C759"))
                    .padding(.leading, 4)
            } compactTrailing: {
                Text(context.state.checkInTime, style: .timer)
                    .monospacedDigit()
                    .foregroundStyle(Color(hex: "34C759"))
                    .frame(width: 50)
            } minimal: {
                Image(systemName: "figure.run")
                    .foregroundStyle(Color(hex: "34C759"))
            }
        }
    }
}

