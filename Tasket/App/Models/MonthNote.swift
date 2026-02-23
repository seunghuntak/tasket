import Foundation
import SwiftData

@Model
final class MonthNote {
    @Attribute(.unique) var monthKey: String  // "YYYY-MM"
    var text: String
    var updatedAt: Date

    init(monthKey: String, text: String = "", updatedAt: Date = .now) {
        self.monthKey = monthKey
        self.text = text
        self.updatedAt = updatedAt
    }
}
