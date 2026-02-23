import SwiftUI

private enum MainTab: Int {
    case plain = 0
    case day = 1
    case month = 2
}

struct RootTabView: View {
    @State private var showSettings = false
    @State private var tab: MainTab = .plain

    @AppStorage(AppSettings.themeKey, store: UserDefaults(suiteName: AppGroup.id))
    private var themeRaw: String = ThemeOption.system.rawValue

    private var theme: ThemeOption {
        ThemeOption(rawValue: themeRaw) ?? .system
    }

    var body: some View {
        TabView(selection: $tab) {
            PlainView(showSettings: $showSettings)
                .tabItem { Label("All", systemImage: "list.bullet") }
                .tag(MainTab.plain)

            DayView(showSettings: $showSettings)
                .tabItem { Label("Daily", systemImage: "calendar.day.timeline.left") }
                .tag(MainTab.day)

            MonthView(showSettings: $showSettings)
                .tabItem { Label("Monthly", systemImage: "calendar") }
                .tag(MainTab.month)
        }
        .tint(theme.tintColor ?? .accentColor)
        .highPriorityGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }
                    guard abs(dx) > 60 else { return }

                    if dx < 0 {
                        goToNextTab()
                    } else {
                        goToPrevTab()
                    }
                }
        )
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func goToNextTab() {
        switch tab {
        case .plain: tab = .day
        case .day: tab = .month
        case .month: break
        }
    }

    private func goToPrevTab() {
        switch tab {
        case .plain: break
        case .day: tab = .plain
        case .month: tab = .day
        }
    }
}
