import SwiftUI
import SwiftData

struct DayTasksPopup: View {
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]

    @State private var selectedTask: TaskItem?
    @State private var showAdd = false

    @State private var deleteCandidate: TaskItem?
    @State private var showDeleteDialog = false

    // Settings
    @AppStorage(AppSettings.themeKey, store: UserDefaults(suiteName: AppGroup.id))
    private var themeRaw: String = ThemeOption.system.rawValue

    private var accent: Color {
        (ThemeOption(rawValue: themeRaw) ?? .system).tintColor ?? .accentColor
    }

    private var tasksForDay: [TaskItem] {
        let cal = Calendar.current
        let items = allTasks.filter { t in
            guard let d = t.date else { return false }
            return cal.isDate(d, inSameDayAs: date)
        }

        let incomplete = items.filter { !$0.isCompleted }.sorted(by: sortPinnedThenCreatedDesc)
        let complete   = items.filter {  $0.isCompleted }.sorted(by: sortPinnedThenCreatedDesc)
        return incomplete + complete
    }

    var body: some View {
        NavigationStack {
            List {
                if tasksForDay.isEmpty {
                    Text("No tasks.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tasksForDay) { task in
                        let row = TaskRow(
                            title: task.title,
                            subtitle: task.date.map { "Due: \(AppDateFormatting.format($0))" },
                            isCompleted: task.isCompleted,
                            isPinned: task.isPinned,
                            showCircle: true,
                            accent: accent,
                            onToggleComplete: { task.isCompleted.toggle() }
                        )
                        .onTapGesture { selectedTask = task }
                        .contextMenu {
                            Button(task.isPinned ? "Unpin" : "Pin") { task.isPinned.toggle() }
                            Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") { task.isCompleted.toggle() }
                            Button("Delete", role: .destructive) {
                                if task.seriesID != nil {
                                    deleteCandidate = task
                                    showDeleteDialog = true
                                } else {
                                    modelContext.delete(task)
                                }
                            }
                        }

                        row
                    }
                }
            }
            .confirmationDialog(
                "Delete repeated task?",
                isPresented: $showDeleteDialog,
                presenting: deleteCandidate
            ) { task in
                Button("Delete This Task", role: .destructive) {
                    modelContext.delete(task)
                    deleteCandidate = nil
                }

                Button("Delete All in Series", role: .destructive) {
                    guard let sid = task.seriesID else { return }
                    let toDelete = allTasks.filter { $0.seriesID == sid }
                    for t in toDelete { modelContext.delete(t) }
                    deleteCandidate = nil
                }

                Button("Cancel", role: .cancel) {
                    deleteCandidate = nil
                }
            }
            .navigationTitle(AppDateFormatting.format(date))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                TaskEditorSheetWithPrefill(
                    taskToEdit: nil,
                    prefillDate: Calendar.current.startOfDay(for: date)
                )
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task)
            }
        }
    }

    private func sortPinnedThenCreatedDesc(_ a: TaskItem, _ b: TaskItem) -> Bool {
        if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
        return a.createdAt > b.createdAt
    }
}
