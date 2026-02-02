//
//  StatsView.swift
//  Work Attendance
//
//  Created by Davron Usmanov on 02/02/26.
//

import SwiftUI
import Charts

struct StatsView: View {
    @Bindable var viewModel: AttendanceViewModel
    @State private var dailyStats: [AttendanceViewModel.DailyStat] = []
    @State private var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: 24) {
                        chartCard
                        summaryCard
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            dailyStats = await viewModel.calculateWeeklyStats()
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.15, green: 0.15, blue: 0.25)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(.white)
            
            chartView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var chartView: some View {
        Chart {
            ForEach(dailyStats) { stat in
                BarMark(
                    x: .value("Day", stat.weekday),
                    y: .value("Hours", stat.hours)
                )
                .foregroundStyle(isDateSelected(stat.date) ? Color.green : Color.green.opacity(0.3))
                .cornerRadius(8)
                .annotation(position: .top, alignment: .center) {
                    Text("\(String(format: "%.1f", stat.hours))h")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if let selectedDate, let stat = dailyStats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                RuleMark(x: .value("Selected", stat.weekday))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .zIndex(-1)
                    .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        valuePopover(stat: stat)
                    }
            }
        }
        .frame(height: 250)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel() {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)h")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date: String = proxy.value(atX: x) {
                                    // Find stat with this weekday
                                    if let stat = dailyStats.first(where: { $0.weekday == date }) {
                                        selectedDate = stat.date
                                    }
                                }
                            }
                            .onEnded { _ in
                                selectedDate = nil
                            }
                    )
            }
        }
    }
    
    @ViewBuilder
    private var summaryCard: some View {
        if let lastStat = dailyStats.last {
             VStack(spacing: 12) {
                 Text("Today's Progress")
                     .font(.headline)
                     .foregroundStyle(.white)
                     .frame(maxWidth: .infinity, alignment: .leading)
                 
                 HStack {
                     VStack(alignment: .leading) {
                         Text("\(String(format: "%.1f", lastStat.hours))")
                             .font(.system(size: 44, weight: .bold))
                             .foregroundStyle(.white)
                         Text("Hours Worked")
                             .font(.caption)
                             .foregroundStyle(.white.opacity(0.6))
                     }
                     Spacer()
                     CircularProgressView(progress: lastStat.hours / 8.0)
                         .frame(width: 80, height: 80)
                 }
             }
             .padding(24)
             .background(
                 RoundedRectangle(cornerRadius: 20)
                     .fill(Color.white.opacity(0.05))
             )
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func valuePopover(stat: AttendanceViewModel.DailyStat) -> some View {
        VStack(spacing: 2) {
            Text("\(String(format: "%.2f", stat.hours)) hrs")
                .font(.headline)
                .foregroundStyle(.black)
            Text(stat.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding(8)
        .background(Color.white.cornerRadius(8))
        .shadow(radius: 4)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 12
                )
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.green,
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
}
