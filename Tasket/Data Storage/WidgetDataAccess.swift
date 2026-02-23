import Foundation
import SwiftData

// MARK: - Widget models (lightweight)

struct WidgetTask: Identifiable, Hashable {
    let id: String          // uuid string
    let title: String
    let isCompleted: Bool
    let isPinned: Bool
    let date: Date?
}

struct WidgetCounts: Hashable {
    let done: Int
    let left: Int
}

// MARK: - Month grid models

struct WidgetMonthDayCounts: Hashable {
    let incomplete: Int
    let complete: Int
}

struct WidgetMonthGridCell: Identifiable, Hashable {
    let id: String
    let date: Date?
    let isInDisplayedMonth: Bool
    let dayNumber: Int?
    let counts: WidgetMonthDayCounts
}

// MARK: - Data access

enum WidgetDataAccess {

    // Upcoming (plain) (limit: Int = n) 'n' is max number tasks to show in a widget
    static func fetchUpcoming(limit: Int = 4) -> [WidgetTask] {
        let context = ModelContext(SharedModelContainer.container)
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let filtered = all.filter { t in
            // Hide repeated tasks
            guard t.seriesID == nil else { return false }

            // Existing rule: hide past-dated tasks, keep undated
            guard let d = t.date else { return true }
            return cal.startOfDay(for: d) >= today
        }

        let sorted = filtered.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            if a.isCompleted != b.isCompleted { return !a.isCompleted && b.isCompleted }

            switch (a.date, b.date) {
            case (nil, nil):
                return a.createdAt > b.createdAt
            case (nil, _):
                return true
            case (_, nil):
                return false
            case let (da?, db?):
                if da != db { return da < db }
                return a.createdAt > b.createdAt
            }
        }

        return sorted.prefix(limit).map(mapTask)
    }

    // Today (day)
    static func fetchToday(limit: Int = 4) -> [WidgetTask] {
        let context = ModelContext(SharedModelContainer.container)
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let todayTasks = all.filter { t in
            guard let d = t.date else { return false }
            return cal.isDate(d, inSameDayAs: today)
        }

        let sorted = todayTasks.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            if a.isCompleted != b.isCompleted { return !a.isCompleted && b.isCompleted }
            return a.createdAt > b.createdAt
        }

        return sorted.prefix(limit).map(mapTask)
    }

    // Month list (optional)
    static func fetchThisMonth(limit: Int = 6) -> [WidgetTask] {
        let context = ModelContext(SharedModelContainer.container)
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []

        let cal = Calendar.current
        let now = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let startNextMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth)!

        let monthTasks = all.filter { t in
            guard let d = t.date else { return false }
            return d >= startOfMonth && d < startNextMonth
        }

        let sorted = monthTasks.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            if a.isCompleted != b.isCompleted { return !a.isCompleted && b.isCompleted }
            if let da = a.date, let db = b.date, da != db { return da < db }
            return a.createdAt > b.createdAt
        }

        return sorted.prefix(limit).map(mapTask)
    }

    static func fetchTodayCounts() -> WidgetCounts {
        let context = ModelContext(SharedModelContainer.container)
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let todayTasks = all.filter { t in
            guard let d = t.date else { return false }
            return cal.isDate(d, inSameDayAs: today)
        }

        let done = todayTasks.filter { $0.isCompleted }.count
        let left = todayTasks.filter { !$0.isCompleted }.count
        return WidgetCounts(done: done, left: left)
    }

    // MARK: - Month grid

    static func fetchMonthGrid(for monthAnchor: Date) -> [WidgetMonthGridCell] {
        let cal = Calendar.current
        let context = ModelContext(SharedModelContainer.container)
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []

        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor))!
        let startNextMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth)!

        // counts keyed by day-start
        var map: [Date: WidgetMonthDayCounts] = [:]

        for t in all {
            guard let d = t.date else { continue }
            guard d >= startOfMonth && d < startNextMonth else { continue }

            let dayStart = cal.startOfDay(for: d)
            let existing = map[dayStart] ?? .init(incomplete: 0, complete: 0)

            if t.isCompleted {
                map[dayStart] = .init(incomplete: existing.incomplete, complete: existing.complete + 1)
            } else {
                map[dayStart] = .init(incomplete: existing.incomplete + 1, complete: existing.complete)
            }
        }

        let daysInMonth = cal.range(of: .day, in: .month, for: startOfMonth)!.count

        // leading blanks
        let firstWeekdayIndex = cal.component(.weekday, from: startOfMonth) // 1..7
        let leadingBlanks = firstWeekdayIndex - cal.firstWeekday
        let normalizedLeading = (leadingBlanks + 7) % 7

        var cells: [WidgetMonthGridCell] = []

        for i in 0..<normalizedLeading {
            cells.append(.init(
                id: "blankL-\(i)",
                date: nil,
                isInDisplayedMonth: false,
                dayNumber: nil,
                counts: .init(incomplete: 0, complete: 0)
            ))
        }

        for day in 1...daysInMonth {
            let d = cal.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            let dayStart = cal.startOfDay(for: d)
            let counts = map[dayStart] ?? .init(incomplete: 0, complete: 0)

            cells.append(.init(
                id: "day-\(dayStart.timeIntervalSince1970)",
                date: d,
                isInDisplayedMonth: true,
                dayNumber: day,
                counts: counts
            ))
        }

        while cells.count % 7 != 0 {
            cells.append(.init(
                id: "blankT-\(cells.count)",
                date: nil,
                isInDisplayedMonth: false,
                dayNumber: nil,
                counts: .init(incomplete: 0, complete: 0)
            ))
        }

        return cells
    }

    // MARK: - Formatting / Links

    static func monthTitle(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        return df.string(from: date)
    }

    static func dayLinkURL(_ date: Date) -> URL? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let s = df.string(from: date)
        return URL(string: "tasket://day?date=\(s)")
    }

    // MARK: - Map

    private static func mapTask(_ t: TaskItem) -> WidgetTask {
        WidgetTask(
            id: t.uuid.uuidString,
            title: t.title,
            isCompleted: t.isCompleted,
            isPinned: t.isPinned,
            date: t.date
        )
    }
}
