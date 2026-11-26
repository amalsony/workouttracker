//
//  StreakCalendarView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/23/26.
//

import SwiftUI

struct StreakCalendarView: View {

    let workouts: [Workout]
    @State private var selectedDate = Date.now

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let days = monthDays
        let activeDays = workoutDays
        let streak = currentStreak

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak > 0 ? .orange : .secondary)
                if streak > 0 {
                    Text("\(streak)").font(.title2.bold())
                    Text("day streak").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("Start your streak").font(.subheadline).foregroundStyle(.secondary)
                }
            }

            HStack {
                monthButton("Previous month", icon: "chevron.left", offset: -1)
                Text(monthStart, format: .dateTime.month(.wide).year())
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .contentTransition(.opacity)
                monthButton("Next month", icon: "chevron.right", offset: 1)
            }

            LazyVGrid(columns: columns, spacing: 6) {
                // Leading blanks so the bottom row stays full (extra space lands top-left).
                ForEach(0..<((7 - days.count % 7) % 7), id: \.self) { _ in
                    Color.clear.frame(height: 34)
                }

                ForEach(days, id: \.self) { day in
                    let active = activeDays.contains(day)
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
            .id(monthStart)
            .transition(.opacity)
        }
        .padding()
        .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onEnded { drag in
                    let movement = drag.translation
                    guard abs(movement.width) >= 44, abs(movement.width) > abs(movement.height) else { return }
                    showMonth(offset: movement.width > 0 ? -1 : 1)
                }
        )
    }

    private func monthButton(_ label: String, icon: String, offset: Int) -> some View {
        Button {
            showMonth(offset: offset)
        } label: {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func showMonth(offset: Int) {
        guard let nextMonth = calendar.date(byAdding: .month, value: offset, to: monthStart) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedDate = nextMonth
        }
    }

    private var workoutDays: Set<Date> {
        Set(workouts.map { calendar.startOfDay(for: $0.date) })
    }

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
    }

    private var monthDays: [Date] {
        let start = monthStart
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        return (0..<range.count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
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
