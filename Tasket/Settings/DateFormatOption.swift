import Foundation

enum DateFormatOption: String, CaseIterable, Identifiable {
    case mdY = "M/d/yyyy"
    case dMY = "d/M/yyyy"
    case iso = "yyyy-MM-dd"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .mdY: return "M/d/yyyy"
        case .dMY: return "d/M/yyyy"
        case .iso: return "yyyy-MM-dd"
        }
    }
}

struct DateFormatterFactory {
    static func make(_ format: DateFormatOption) -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = format.rawValue
        return df
    }
}

extension Calendar {
    func startOfDay(_ date: Date) -> Date { startOfDay(for: date) }

    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        isDate(a, inSameDayAs: b)
    }

    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }

    func daysInMonth(for date: Date) -> Int {
        range(of: .day, in: .month, for: date)!.count
    }
}
