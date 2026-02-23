import AppIntents
import SwiftData

@available(iOS 17.0, *)
struct ToggleTaskCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Completion"

    @Parameter(title: "Task UUID")
    var taskUUID: String

    init() {}
    init(taskUUID: String) { self.taskUUID = taskUUID }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskUUID) else { return .result() }

        let container = SharedModelContainer.container
        let context = ModelContext(container)

        let fd = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.uuid == uuid })
        if let task = try context.fetch(fd).first {
            task.isCompleted.toggle()
            try context.save()
        }

        return .result()
    }
}
