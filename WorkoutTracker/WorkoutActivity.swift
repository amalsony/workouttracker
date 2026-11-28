import Foundation

struct WorkoutWeek: Identifiable {
    let start: Date
    let workoutCount: Int
    let activeDayCount: Int

    var id: Date { start }

    static func recentWeeks(
        workoutDates: [Date],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Self] {
        guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }

        let starts: [Date] = (0..<6).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeek.start) else { return nil }
            return calendar.dateInterval(of: .weekOfYear, for: day)?.start
        }
        guard let firstWeek = starts.first else { return [] }

        let today = calendar.startOfDay(for: now)
        var daysByWeek: [Date: [Date]] = [:]
        for date in workoutDates where date >= firstWeek {
            let day = calendar.startOfDay(for: date)
            guard day <= today,
                  let week = calendar.dateInterval(of: .weekOfYear, for: date) else { continue }
            daysByWeek[week.start, default: []].append(day)
        }

        return starts.map { start in
            let days = daysByWeek[start, default: []]
            return Self(start: start, workoutCount: days.count, activeDayCount: Set(days).count)
        }
    }
}
