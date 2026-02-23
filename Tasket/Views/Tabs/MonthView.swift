import SwiftUI
import SwiftData

struct MonthView: View {
    @Binding var showSettings: Bool

    @Query private var allTasks: [TaskItem]
    @Query private var allNotes: [MonthNote]
    @State private var showNoteEditor = false

    @State private var monthAnchor: Date = Calendar.current.startOfMonth(for: .now)

    @State private var selectedDateForPopup: Date?
    @State private var showAdd = false
    @State private var showMonthPicker = false

    @AppStorage(AppSettings.themeKey, store: UserDefaults(suiteName: AppGroup.id))
    private var themeRaw: String = ThemeOption.system.rawValue
    @AppStorage(AppSettings.hideNavBarWhenSwipeViewsOnKey) private var hideNavBarWhenSwipeOn: Bool = false
    
    private var currentMonthKey: String {
        Calendar.current.monthKey(for: monthAnchor)
    }

    private var currentMonthNote: MonthNote? {
        allNotes.first(where: { $0.monthKey == currentMonthKey })
    }
    
    private var monthNoteCard: some View {
        Button {
            showNoteEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Monthly Note")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }

                if let note = currentMonthNote, !note.text.isEmpty {
                    Text(note.text)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                } else {
                    Text("Tap to add a note for this month…")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
        .sheet(isPresented: $showNoteEditor) {
            MonthNoteEditorSheet(monthKey: currentMonthKey)
        }
    }


    private var navHidden: Bool {
        hideNavBarWhenSwipeOn
    }

    private var themeDotColor: Color {
        let theme = ThemeOption(rawValue: themeRaw) ?? .system
        return theme.tintColor ?? .accentColor
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var cells: [Cell] {
        calendarCells(for: monthAnchor)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                monthHeader
                weekdayHeader

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cells, id: \.id) { cell in
                        if let dayDate = cell.date {
                            MonthDayCell(
                                date: dayDate,
                                isInDisplayedMonth: cell.isInDisplayedMonth,
                                incompleteCount: counts(for: dayDate).incomplete,
                                completeCount: counts(for: dayDate).complete,
                                incompleteDotColor: themeDotColor
                            )
                            .onTapGesture {
                                selectedDateForPopup = dayDate
                            }
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
                monthNoteCard

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            //.navigationTitle("Month") // looks ugly, but save it for later.
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                TaskEditorSheetWithPrefill(taskToEdit: nil, prefillDate: nil)
            }
            .sheet(item: $selectedDateForPopup) { date in
                DayTasksPopup(date: date)
            }
            .sheet(isPresented: $showMonthPicker) {
                MonthYearPickerSheet(
                    selectedMonth: $monthAnchor
                )
            }
            .applyNavBarVisibilitySetting()
            .overlay(alignment: .topTrailing) {
                if navHidden {
                    FloatingControls(
                        onSettings: { showSettings = true },
                        onAdd: { showAdd = true }
                    )
                }
            }
        }
    }

    // MARK: Header

    private var monthHeader: some View {
        HStack {
            Button {
                monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor)!
                monthAnchor = Calendar.current.startOfMonth(for: monthAnchor)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Button {
                showMonthPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(monthTitle(monthAnchor))
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor)!
                monthAnchor = Calendar.current.startOfMonth(for: monthAnchor)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal, 4)
    }

    private var weekdayHeader: some View {
        let cal = Calendar.current
        let symbols = cal.shortStandaloneWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { s in
                Text(s)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Counts

    private func counts(for day: Date) -> (incomplete: Int, complete: Int) {
        let cal = Calendar.current
        var incomplete = 0
        var complete = 0

        for t in allTasks {
            guard let d = t.date else { continue }
            if cal.isDate(d, inSameDayAs: day) {
                if t.isCompleted { complete += 1 } else { incomplete += 1 }
            }
        }
        return (incomplete, complete)
    }

    // MARK: Cells

    private struct Cell: Identifiable {
        let id: String
        let date: Date?
        let isInDisplayedMonth: Bool
    }

    private func calendarCells(for month: Date) -> [Cell] {
        let cal = Calendar.current
        let startOfMonth = cal.startOfMonth(for: month)
        let days = cal.daysInMonth(for: month)

        let firstWeekdayIndex = cal.component(.weekday, from: startOfMonth)
        let leadingBlanks = (firstWeekdayIndex - cal.firstWeekday + 7) % 7

        var cells: [Cell] = []

        for i in 0..<leadingBlanks {
            cells.append(Cell(id: "blank-\(i)", date: nil, isInDisplayedMonth: false))
        }

        let year = cal.component(.year, from: startOfMonth)
        let monthNum = cal.component(.month, from: startOfMonth)

        for day in 1...days {
            let d = cal.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            let key = "\(year)-\(monthNum)-\(day)"
            cells.append(Cell(id: key, date: d, isInDisplayedMonth: true))
        }

        return cells
    }

    private func monthTitle(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        return df.string(from: date)
    }
    
}
extension Date: Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
