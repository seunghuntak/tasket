import SwiftUI

enum ThemeOption: String, CaseIterable, Identifiable {
    case system
    case blue
    case green
    case purple
    case orange
    case red

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var tintColor: Color? {
        switch self {
        case .system: return nil
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        }
    }
}

struct AppSettings {
    static let themeKey = "themeOption"
    static let dateFormatKey = "dateFormatOption"
    static let hideNavBarWhenSwipeViewsOnKey = "hideNavBarWhenSwipeViewsOn"

}

