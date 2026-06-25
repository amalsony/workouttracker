//
//  StreakCalendarView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/23/26.
//

import SwiftUI

/// <#Description#>
struct StreakCalendarView: View {

    let workouts: [Workout]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(currentStreak > 0 ? .orange : .secondary)
                if currentStreak > 0 {
                    Text("\(currentStreak)").font(.title2.bold())
                    Text("day streak").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("Start your streak").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(monthTitle).font(.subheadline).foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 6) {
                // Leading blanks so the bottom row stays full (extra space lands top-left).
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 34)
                }

                ForEach(monthDays, id: \.self) { day in
                    let active = workoutDays.contains(day)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(active ? Color.accentColor : Color.gray.opacity(0.15))
                        .frame(height: 34)
                        .overlay {
                            Text("\(calendar.component(.day, from: day))")
                                .font(.caption2)
                                .foregroundStyle(active ? .white : .secondary)
                        }
                        .overlay {
                            if calendar.isDateInToday(day) {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.primary, lineWidth: 1.5)
                            }
                        }
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var workoutDays: Set<Date> {
        Set(workouts.map { calendar.startOfDay(for: $0.date) })
    }

    // Every day in the current calendar month, 1st → last.
    private var monthDays: [Date] {
        let today = calendar.startOfDay(for: .now)
        guard let interval = calendar.dateInterval(of: .month, for: today),
              let range = calendar.range(of: .day, in: .month, for: today) else { return [] }
        return range.compactMap { offset in
            calendar.date(byAdding: .day, value: offset - 1, to: interval.start)
        }
    }

    // Pad the front so total cells are a multiple of 7 → bottom row is always full.
    private var leadingBlanks: Int {
        let remainder = monthDays.count % 7
        return remainder == 0 ? 0 : 7 - remainder
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: .now)
    }

    private var currentStreak: Int {
        let days = workoutDays
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        if !days.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        while days.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}
