import Foundation

enum RepeatFrequency: String, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

struct RepeatConfig {
    var frequency: RepeatFrequency
    /// For weekly: weekdays as Calendar weekday numbers (1=Sun ... 7=Sat)
    var weekdays: Set<Int>
    var startDate: Date
    var endDate: Date
}

enum RepeatGeneration {
    static func generateDates(config: RepeatConfig, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: config.startDate)
        let end = calendar.startOfDay(for: config.endDate)
        guard start <= end else { return [] }

        switch config.frequency {
        case .daily:
            return generateDaily(from: start, to: end, calendar: calendar)

        case .weekly:
            // If user didn’t choose any weekday, default to weekday of startDate
            let weekdays = config.weekdays.isEmpty
            ? [calendar.component(.weekday, from: start)]
            : Array(config.weekdays).sorted()

            return generateWeekly(from: start, to: end, weekdays: weekdays, calendar: calendar)
        }
    }

    private static func generateDaily(from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        var dates: [Date] = []
        var cursor = start
        while cursor <= end {
            dates.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }
        return dates
    }

    private static func generateWeekly(from start: Date, to end: Date, weekdays: [Int], calendar: Calendar) -> [Date] {
        var dates: [Date] = []

        // Iterate day-by-day; cheap enough for typical ranges (weeks/months).
        // optimize later when you add monthly/yearly.
        var cursor = start
        while cursor <= end {
            let wd = calendar.component(.weekday, from: cursor) // 1..7
            if weekdays.contains(wd) {
                dates.append(cursor)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }
        return dates
    }
}
