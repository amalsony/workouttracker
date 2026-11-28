//
//  StatsView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/17/26.
//

import Charts
import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView(
                        "No Activity Yet",
                        systemImage: "chart.bar",
                        description: Text("Log a workout to see how often you train.")
                    )
                } else {
                    let weeks = WorkoutWeek.recentWeeks(workoutDates: workouts.map(\.date), calendar: calendar)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if let currentWeek = weeks.last {
                                weeklySummary(currentWeek)
                            }
                            activityChart(weeks)
                        }
                        .padding()
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }

    private func weeklySummary(_ week: WorkoutWeek) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))

        return VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            layout {
                stat("Workouts", value: week.workoutCount)
                stat("Active days", value: week.activeDayCount)
            }
        }
    }

    private func stat(_ title: LocalizedStringKey, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value, format: .number)
                .font(.largeTitle.bold().monospacedDigit())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 16))
    }

    private func activityChart(_ weeks: [WorkoutWeek]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workouts by week")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text("Last 6 weeks")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if weeks.contains(where: { $0.workoutCount > 0 }) {
                Chart(weeks) { week in
                    BarMark(
                        x: .value("Week starting", weekLabel(week)),
                        y: .value("Workouts", week.workoutCount)
                    )
                    .foregroundStyle(
                        week.id == weeks.last?.id ? Color.accentColor : Color.accentColor.opacity(0.45)
                    )
                    .cornerRadius(4)
                    .accessibilityLabel(Text("Week of \(week.start, format: .dateTime.month(.wide).day())"))
                }
                .chartXScale(domain: weeks.map(weekLabel))
                .chartXAxis {
                    AxisMarks { AxisValueLabel() }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(minimumStride: 1.0, desiredCount: 4)) {
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 190)
            } else {
                Text("No workouts in these six weeks.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 16))
    }

    private func weekLabel(_ week: WorkoutWeek) -> String {
        week.start.formatted(.dateTime.month(.abbreviated).day())
    }
}

#Preview {
    StatsView()
        .modelContainer(for: Workout.self, inMemory: true)
}
