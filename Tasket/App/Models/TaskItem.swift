import Foundation
import SwiftData

@Model
final class TaskItem {
    
    var uuid: UUID
    
    var title: String
    var date: Date?          // nil = undated (repeat tasks should NOT be nil)
    var memo: String
    var isCompleted: Bool
    var isPinned: Bool
    var createdAt: Date

    // MARK: Repeat / Series
    // If nil => normal single task
    // If not nil => this task is one occurrence in a series
    var seriesID: UUID?

    init(
        title: String,
        date: Date? = nil,
        memo: String = "",
        isCompleted: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = .now,
        seriesID: UUID? = nil
    ) {
        self.uuid = UUID()
        self.title = title
        self.date = date
        self.memo = memo
        self.isCompleted = isCompleted
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.seriesID = seriesID
    }
}
