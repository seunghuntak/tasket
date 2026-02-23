import SwiftUI
import SwiftData

struct PlainView: View {
    @Binding var showSettings: Bool

    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]

    @State private var showAdd = false
    @State private var selectedTask: TaskItem?

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

    // Data rules: show completed but push down; hide past-dated tasks; undated to top
    private var visibleTasks: [TaskItem] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        let filtered = allTasks.filter { task in
            if task.seriesID != nil { return false }
            // Hide passed dated tasks (regardless of completion)
            guard let d = task.date else { return true }
            return cal.startOfDay(for: d) >= today
        }

        let incomplete = filtered.filter { !$0.isCompleted }.sorted(by: plainSort)
        let completed  = filtered.filter {  $0.isCompleted }.sorted(by: plainSort)

        return incomplete + completed
    }

    private func plainSort(_ a: TaskItem, _ b: TaskItem) -> Bool {
        // Pinned goes up
        if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }

        // Undated goes up
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

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleTasks) { task in
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
            .navigationTitle("Upcoming")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                TaskEditorSheet(taskToEdit: nil)
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task)
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
}
