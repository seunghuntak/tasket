import SwiftUI
import SwiftData

struct TaskEditorSheetWithPrefill: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let taskToEdit: TaskItem?
    let prefillDate: Date?

    @State private var title: String = ""
    @State private var hasDate: Bool = false
    @State private var date: Date = .now
    @State private var memo: String = ""

    // Repeat
    @State private var isRepeating: Bool = false
    @State private var repeatFrequency: RepeatFrequency = .daily
    @State private var repeatWeekdays: Set<Int> = []
    @State private var repeatStart: Date = Calendar.current.startOfDay(for: .now)
    @State private var repeatEnd: Date = Calendar.current.startOfDay(
        for: Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    )

    init(taskToEdit: TaskItem?, prefillDate: Date? = nil) {
        self.taskToEdit = taskToEdit
        self.prefillDate = prefillDate
    }

    private var isEditing: Bool { taskToEdit != nil }

    private var normalizedSingleDate: Date? {
        hasDate ? Calendar.current.startOfDay(for: date) : nil
    }

    private var repeatRangeValid: Bool {
        Calendar.current.startOfDay(for: repeatEnd) >= Calendar.current.startOfDay(for: repeatStart)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && (!isRepeating || repeatRangeValid)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)

                    Toggle("Set Date", isOn: $hasDate)

                    if hasDate {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                    }

                    TextField("Memo", text: $memo, axis: .vertical)
                        .lineLimit(4...10)
                }

                Section("Repeat") {
                    Toggle("Repeat", isOn: $isRepeating)
                        .disabled(isEditing) // keep editing simple: editing affects only this one occurrence

                    if isEditing, isRepeating {
                        Text("Repeat settings can only be set when creating a new task.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isRepeating && !isEditing {
                        Picker("Frequency", selection: $repeatFrequency) {
                            ForEach(RepeatFrequency.allCases) { f in
                                Text(f.displayName).tag(f)
                            }
                        }

                        if repeatFrequency == .weekly {
                            WeekdayPicker(selected: $repeatWeekdays)
                        }

                        DatePicker("Start", selection: $repeatStart, displayedComponents: [.date])
                        DatePicker("End", selection: $repeatEnd, displayedComponents: [.date])

                        if !repeatRangeValid {
                            Text("End date must be on or after start date.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(taskToEdit == nil ? "Add Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { preload() }
        }
    }

    private func preload() {
        if let t = taskToEdit {
            title = t.title
            memo = t.memo
            if let d = t.date {
                hasDate = true
                date = d
            } else {
                hasDate = false
                date = .now
            }

            // editing: keep repeat off in UI (we don’t infer series behavior here)
            isRepeating = false
        } else if let d = prefillDate {
            let day = Calendar.current.startOfDay(for: d)
            hasDate = true
            date = day
            repeatStart = day
        } else {
            let day = Calendar.current.startOfDay(for: .now)
            repeatStart = day
        }
    }

    private func save() {
        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        // EDIT existing single task
        if let t = taskToEdit {
            t.title = finalTitle
            t.memo = finalMemo
            t.date = normalizedSingleDate
            dismiss()
            return
        }

        // CREATE new tasks
        if isRepeating && !isEditing {
            createRepeatedTasks(title: finalTitle, memo: finalMemo)
        } else {
            modelContext.insert(TaskItem(title: finalTitle, date: normalizedSingleDate, memo: finalMemo))
        }

        dismiss()
    }

    private func createRepeatedTasks(title: String, memo: String) {
        // repeating must have dates
        let start = Calendar.current.startOfDay(for: repeatStart)
        let end = Calendar.current.startOfDay(for: repeatEnd)

        let seriesID = UUID()

        switch repeatFrequency {
        case .daily:
            for d in datesDaily(from: start, to: end) {
                let item = TaskItem(title: title, date: d, memo: memo)
                item.seriesID = seriesID
                modelContext.insert(item)
            }

        case .weekly:
            var weekdays = repeatWeekdays
            if weekdays.isEmpty {
                let wd = Calendar.current.component(.weekday, from: start) // 1..7
                weekdays.insert(wd)
            }

            for d in datesWeekly(from: start, to: end, weekdays: weekdays) {
                let item = TaskItem(title: title, date: d, memo: memo)
                item.seriesID = seriesID
                modelContext.insert(item)
            }
        }
    }

    // MARK: - Date generators

    private func datesDaily(from start: Date, to end: Date) -> [Date] {
        var out: [Date] = []
        var cur = start
        while cur <= end {
            out.append(cur)
            cur = Calendar.current.date(byAdding: .day, value: 1, to: cur)!
        }
        return out
    }

    private func datesWeekly(from start: Date, to end: Date, weekdays: Set<Int>) -> [Date] {
        var out: [Date] = []
        var cur = start
        while cur <= end {
            let wd = Calendar.current.component(.weekday, from: cur) // 1..7
            if weekdays.contains(wd) {
                out.append(cur)
            }
            cur = Calendar.current.date(byAdding: .day, value: 1, to: cur)!
        }
        return out
    }
}


