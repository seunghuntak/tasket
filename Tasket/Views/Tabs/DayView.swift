import SwiftUI
import SwiftData

struct DayView: View {
    @Binding var showSettings: Bool

    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]

    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @State private var showAdd = false
    @State private var selectedTask: TaskItem?
    @State private var showDayPicker = false

    @State private var deleteCandidate: TaskItem?
    @State private var showDeleteDialog = false

    // Settings
    @AppStorage(AppSettings.themeKey, store: UserDefaults(suiteName: AppGroup.id))
    private var themeRaw: String = ThemeOption.system.rawValue
    @AppStorage(AppSettings.hideNavBarWhenSwipeViewsOnKey) private var hideNavBarWhenSwipeOn: Bool = false

    private var navHidden: Bool { hideNavBarWhenSwipeOn }

    private var accent: Color {
        (ThemeOption(rawValue: themeRaw) ?? .system).tintColor ?? .accentColor
    }

    private var navTitle: String {
        Calendar.current.isDateInToday(selectedDay) ? "Today" : AppDateFormatting.format(selectedDay)
    }

    private var dayTasks: [TaskItem] {
        let cal = Calendar.current
        let tasksForDay = allTasks.filter { task in
            guard let d = task.date else { return false }
            return cal.isDate(d, inSameDayAs: selectedDay)
        }

        let incomplete = tasksForDay.filter { !$0.isCompleted }.sorted(by: sortPinnedThenCreatedDesc)
        let completed  = tasksForDay.filter {  $0.isCompleted }.sorted(by: sortPinnedThenCreatedDesc)
        return incomplete + completed
    }

    var body: some View {
        NavigationStack {
            List {
                if dayTasks.isEmpty {
                    Text("No tasks for this day.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dayTasks) { task in
                        let row = TaskRow(
                            title: task.title,
                            subtitle: nil,
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
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showDayPicker = true } label: { Image(systemName: "calendar") }
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                TaskEditorPrefillDateSheet(prefillDate: selectedDay)
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task)
            }
            .sheet(isPresented: $showDayPicker) {
                DayPickerSheet(selectedDay: $selectedDay)
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

    private func sortPinnedThenCreatedDesc(_ a: TaskItem, _ b: TaskItem) -> Bool {
        if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
        return a.createdAt > b.createdAt
    }
}
