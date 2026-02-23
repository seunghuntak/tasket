import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import Foundation

// MARK: - Shared Entry

struct TaskListEntry: TimelineEntry {
    let date: Date
    let title: String
    let tasks: [WidgetTask]
}

struct CountEntry: TimelineEntry {
    let date: Date
    let counts: WidgetCounts
}

// MARK: - Providers

struct UpcomingProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskListEntry {
        TaskListEntry(date: .now, title: "Upcoming", tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskListEntry) -> Void) {
        completion(TaskListEntry(date: .now, title: "Upcoming", tasks: WidgetDataAccess.fetchUpcoming()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskListEntry>) -> Void) {
        let entry = TaskListEntry(date: .now, title: "Upcoming", tasks: WidgetDataAccess.fetchUpcoming())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskListEntry {
        TaskListEntry(date: .now, title: "Today", tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskListEntry) -> Void) {
        completion(TaskListEntry(date: .now, title: "Today", tasks: WidgetDataAccess.fetchToday()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskListEntry>) -> Void) {
        let entry = TaskListEntry(date: .now, title: "Today", tasks: WidgetDataAccess.fetchToday())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct MonthProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskListEntry {
        TaskListEntry(date: .now, title: "This Month", tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskListEntry) -> Void) {
        completion(TaskListEntry(date: .now, title: "This Month", tasks: WidgetDataAccess.fetchThisMonth()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskListEntry>) -> Void) {
        let entry = TaskListEntry(date: .now, title: "This Month", tasks: WidgetDataAccess.fetchThisMonth())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct LockCountsProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountEntry {
        CountEntry(date: .now, counts: .init(done: 0, left: 0))
    }

    func getSnapshot(in context: Context, completion: @escaping (CountEntry) -> Void) {
        completion(CountEntry(date: .now, counts: WidgetDataAccess.fetchTodayCounts()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountEntry>) -> Void) {
        let entry = CountEntry(date: .now, counts: WidgetDataAccess.fetchTodayCounts())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct MonthNoteEntry: TimelineEntry {
    let date: Date
    let monthTitle: String
    let noteText: String
    let hasNote: Bool
}

struct MonthNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthNoteEntry {
        MonthNoteEntry(date: .now, monthTitle: "This Month", noteText: "", hasNote: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthNoteEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthNoteEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> MonthNoteEntry {
        let cal = Calendar.current
        let monthKey = cal.monthKey(for: .now) // uses your Calendar extension

        // Fetch MonthNote for current month
        let context = ModelContext(SharedModelContainer.container)
        let fd = FetchDescriptor<MonthNote>(predicate: #Predicate { $0.monthKey == monthKey })

        let note = (try? context.fetch(fd).first)

        let title = WidgetDataAccess.monthTitle(.now)
        let text = note?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let has = !text.isEmpty

        return MonthNoteEntry(date: .now, monthTitle: title, noteText: text, hasNote: has)
    }
}

struct MonthGridEntry: TimelineEntry {
    let date: Date
    let monthAnchor: Date
    let monthTitle: String
    let cells: [WidgetMonthGridCell]
}

struct MonthGridProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthGridEntry {
        MonthGridEntry(date: .now, monthAnchor: .now, monthTitle: WidgetDataAccess.monthTitle(.now), cells: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthGridEntry) -> Void) {
        let anchor = Date()
        completion(MonthGridEntry(
            date: .now,
            monthAnchor: anchor,
            monthTitle: WidgetDataAccess.monthTitle(anchor),
            cells: WidgetDataAccess.fetchMonthGrid(for: anchor)
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthGridEntry>) -> Void) {
        let anchor = Date()
        let entry = MonthGridEntry(
            date: .now,
            monthAnchor: anchor,
            monthTitle: WidgetDataAccess.monthTitle(anchor),
            cells: WidgetDataAccess.fetchMonthGrid(for: anchor)
        )
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget Theme

private struct WidgetTheme {
    @AppStorage(AppSettings.themeKey, store: UserDefaults(suiteName: AppGroup.id))
    var themeRaw: String = ThemeOption.system.rawValue

    var tint: Color {
        (ThemeOption(rawValue: themeRaw) ?? .system).tintColor ?? .accentColor
    }
}

// MARK: - Views

struct MonthGridWidgetView: View {
    let entry: MonthGridEntry
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(entry.monthTitle)
                .font(.title2.weight(.semibold))
                .padding(.top, 12)

            HStack {
                ForEach(Calendar.current.shortStandaloneWeekdaySymbols, id: \.self) { s in
                    Text(s)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(entry.cells) { cell in
                    if let date = cell.date,
                       let day = cell.dayNumber {

                        MonthGridCellView(
                            day: day,
                            isToday: Calendar.current.isDateInToday(date),
                            incomplete: cell.counts.incomplete,
                            complete: cell.counts.complete
                        )

                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 0)
        .padding(.bottom, 5)
    }
}

struct MonthGridCellView: View {
    let day: Int
    let isToday: Bool
    let incomplete: Int
    let complete: Int

    private var themeTint: Color { WidgetTheme().tint }

    var body: some View {
        VStack(spacing: 6) {

            Text("\(day)")
                .font(.body.weight(isToday ? .bold : .regular))
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                ForEach(0..<min(incomplete, 3), id: \.self) { _ in
                    Circle()
                        .fill(themeTint)
                        .frame(width: 5, height: 5)
                }

                ForEach(0..<min(complete, 3), id: \.self) { _ in
                    Circle()
                        .fill(.gray.opacity(0.6))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(themeTint, lineWidth: 2)
            }
        }
    }
}

struct MonthIndicatorMini: View {
    let incomplete: Int
    let complete: Int
    let incompleteColor: Color

    // small widget-friendly rule:
    // show up to 3 dots for incomplete + 3 for complete
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(incomplete, 3), id: \.self) { _ in
                Circle().fill(incompleteColor).frame(width: 4, height: 4)
            }
            ForEach(0..<min(complete, 3), id: \.self) { _ in
                Circle().fill(.gray).frame(width: 4, height: 4)
            }
        }
        .frame(height: 6)
    }
}

struct TaskRowWidgetView: View {
    let t: WidgetTask

    var body: some View {
        HStack(spacing: 8) {
            if #available(iOS 17.0, *) {
                Button(intent: ToggleTaskCompletionIntent(taskUUID: t.id)) {
                    Image(systemName: t.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: t.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
            }

            Text(t.title)
                .font(.system(size: 14))
                .lineLimit(1)
                .opacity(t.isCompleted ? 0.6 : 1.0)

            Spacer(minLength: 0)

            if t.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11))
                    .opacity(0.65)
            }
        }
        .frame(height: 22)
    }
}

struct TaskListWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskListEntry

    private var maxRows: Int { family == .systemSmall ? 3 : 4 }
    private var pad: CGFloat { family == .systemSmall ? 12 : 14 }
    private var headerBottom: CGFloat { family == .systemSmall ? 6 : 8 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(entry.title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, headerBottom)

            if entry.tasks.isEmpty {
                Text("No tasks.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.tasks.prefix(maxRows)) { t in
                        TaskRowWidgetView(t: t)
                    }
                }

                if entry.tasks.count > maxRows {
                    Text("+\(entry.tasks.count - maxRows) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(pad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// Lock screen views

struct LockCountsCircularView: View {
    let entry: CountEntry

    var body: some View {
        Gauge(value: Double(entry.counts.done),
              in: 0...max(1, Double(entry.counts.done + entry.counts.left))) {
            Text("")
        } currentValueLabel: {
            Text("\(entry.counts.left)")
        }
    }
}

struct LockCountsRectangularView: View {
    let entry: CountEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Today")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Done \(entry.counts.done) • Left \(entry.counts.left)")
                .font(.caption)
        }
    }
}

struct LockWidgetFamilyView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockCountsCircularView(entry: entry)
        case .accessoryRectangular:
            LockCountsRectangularView(entry: entry)
        case .accessoryInline:
            Text("Done \(entry.counts.done) • Left \(entry.counts.left)")
        default:
            LockCountsRectangularView(entry: entry)
        }
    }
}

struct MonthNoteWidgetView: View {
    let entry: MonthNoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(entry.monthTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if entry.hasNote {
                Text(entry.noteText)
                    .font(.body)
                    .lineLimit(6)
                    .foregroundStyle(.primary)
            } else {
                Text("No monthly note.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "tasket://monthnote"))
    }
}

// MARK: - Widgets

struct UpcomingTasksWidget: Widget {
    let kind = "TasketUpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingProvider()) { entry in
            TaskListWidgetView(entry: entry)
                .modelContainer(SharedModelContainer.container)
                .widgetBackground()
        }
        .configurationDisplayName("Upcoming")
        .description("Interactive upcoming tasks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayTasksWidget: Widget {
    let kind = "TasketTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TaskListWidgetView(entry: entry)
                .modelContainer(SharedModelContainer.container)
                .widgetBackground()
        }
        .configurationDisplayName("Today")
        .description("Interactive tasks due today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MonthTasksWidget: Widget {
    let kind = "TasketMonthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthGridProvider()) { entry in
            MonthGridWidgetView(entry: entry)
                .modelContainer(SharedModelContainer.container)
                .widgetBackground()
        }
        .configurationDisplayName("This Month")
        .description("Calendar view with task indicators.")
        .supportedFamilies([.systemLarge])
    }
}

struct TasketLockWidget: Widget {
    let kind = "TasketLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockCountsProvider()) { entry in
            LockWidgetFamilyView(entry: entry)
                .modelContainer(SharedModelContainer.container)
                .widgetURL(URL(string: "tasket://today"))
                .widgetBackground()
        }
        .configurationDisplayName("Done vs Left")
        .description("Shows how many tasks are done and left today.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

struct MonthNoteWidget: Widget {
    let kind = "TasketMonthNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthNoteProvider()) { entry in
            MonthNoteWidgetView(entry: entry)
                .modelContainer(SharedModelContainer.container)
                .widgetBackground()
        }
        .configurationDisplayName("Month Note")
        .description("Shows your note for this month.")
        .supportedFamilies([.systemMedium])
    }
}
// MARK: - Bundle

@main
struct TasketWidgetBundle: WidgetBundle {
    var body: some Widget {
        UpcomingTasksWidget()
        TodayTasksWidget()
        MonthTasksWidget()
        MonthNoteWidget()
        TasketLockWidget()
    }
}
