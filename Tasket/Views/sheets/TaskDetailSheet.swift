
import SwiftUI

struct TaskDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem

    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(task.title)
                        .font(.title2)
                        .bold()

                    if let memo = task.memo.nilIfEmpty {
                        Text(memo)
                            .font(.body)
                    } else {
                        Text("No memo")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showEditor) {
                TaskEditorSheet(taskToEdit: task)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
