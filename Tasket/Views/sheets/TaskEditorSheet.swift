import SwiftUI
import SwiftData

struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let taskToEdit: TaskItem?

    @State private var title: String = ""
    @State private var hasDate: Bool = false
    @State private var date: Date = .now
    @State private var memo: String = ""

    // Repeat UI
    @State private var isRepeating = false
    @State private var repeatFrequency: RepeatFrequency = .daily
    @State private var repeatWeekdays: Set<Int> = []
    @State private var repeatStart: Date = Calendar.current.startOfDay(for: .now)
    @State private var repeatEnd: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now

    init(taskToEdit: TaskItem?) {
        self.taskToEdit = taskToEdit
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
                    Toggle("Repeat task", isOn: $isRepeating)
                        .disabled(taskToEdit != nil) // keep editing simple & safe for now

                    if taskToEdit != nil {
                        Text("Repeating can be set when creating a task. Editing series will be added later.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isRepeating && taskToEdit == nil {
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

                        if repeatEnd < repeatStart {
                            Text("End date must be on or after start date.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(taskToEdit == nil ? "Add Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(saveDisabled)
                }
            }
            .onAppear { preloadIfNeeded() }
            .onChange(of: isRepeating) { _, newValue in
                // If user turns on repeat, force dated tasks (repeat needs a range)
                if newValue {
                    hasDate = true
                    date = Calendar.current.startOfDay(for: date)
                    repeatStart = Calendar.current.startOfDay(for: date)
                    // default end = +1 month from start
                    repeatEnd = Calendar.current.date(byAdding: .month, value: 1, to: repeatStart) ?? repeatStart
                }
            }
            .onChange(of: date) { _, newValue in
                // keep start aligned with chosen date when repeating
                if isRepeating && taskToEdit == nil {
                    repeatStart = Calendar.current.startOfDay(for: newValue)
                    if repeatEnd < repeatStart {
                        repeatEnd = repeatStart
                    }
                }
            }
        }
    }

    private var saveDisabled: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if isRepeating && taskToEdit == nil {
            if repeatEnd < repeatStart { return true }
        }
        return false
    }

    private func preloadIfNeeded() {
        guard let t = taskToEdit else { return }
        title = t.title
        memo = t.memo
        if let d = t.date {
            hasDate = true
            date = d
        } else {
            hasDate = false
            date = .now
        }

        // Editing: do not enable repeat editing for now.
        isRepeating = false
    }

    private func save() {
        let cal = Calendar.current

        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDate: Date? = hasDate ? cal.startOfDay(for: date) : nil

        if let t = taskToEdit {
            // Editing a single task (including an occurrence)
            t.title = finalTitle
            t.memo = finalMemo
            t.date = finalDate
            dismiss()
            return
        }

        // Creating new task(s)
        if isRepeating {
            // Repeat tasks MUST be dated
            let start = cal.startOfDay(for: repeatStart)
            let end = cal.startOfDay(for: repeatEnd)

            let cfg = RepeatConfig(
                frequency: repeatFrequency,
                weekdays: repeatWeekdays,
                startDate: start,
                endDate: end
            )

            let dates = RepeatGeneration.generateDates(config: cfg, calendar: cal)
            let sid = UUID()

            for d in dates {
                let item = TaskItem(
                    title: finalTitle,
                    date: d,
                    memo: finalMemo,
                    isCompleted: false,
                    isPinned: false,
                    createdAt: .now,
                    seriesID: sid
                )
                modelContext.insert(item)
            }
        } else {
            let item = TaskItem(
                title: finalTitle,
                date: finalDate,
                memo: finalMemo,
                isCompleted: false,
                isPinned: false,
                createdAt: .now,
                seriesID: nil
            )
            modelContext.insert(item)
        }

        dismiss()
    }
}
