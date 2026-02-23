import Foundation
import SwiftUI

struct AppDateFormatting {
    static func format(_ date: Date) -> String {
        let raw = UserDefaults.standard.string(forKey: AppSettings.dateFormatKey)
        let opt = DateFormatOption(rawValue: raw ?? "") ?? .mdY
        return DateFormatterFactory.make(opt).string(from: date)
    }
}
