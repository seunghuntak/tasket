import Foundation

extension Calendar {
    func monthKey(for date: Date) -> String {
        let y = component(.year, from: date)
        let m = component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }
}
