import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.themeKey, store: UserDefaults(suiteName: AppGroup.id))
    private var themeRaw: String = ThemeOption.system.rawValue
    @AppStorage(AppSettings.dateFormatKey) private var dateFormatRaw: String = DateFormatOption.mdY.rawValue
    @AppStorage(AppSettings.hideNavBarWhenSwipeViewsOnKey) private var hideNavBarWhenSwipeOn: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $themeRaw) {
                        ForEach(ThemeOption.allCases) { t in
                            Text(t.displayName).tag(t.rawValue)
                        }
                    }
                    .onChange(of: themeRaw) { _ in
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                }

                Section("Dates") {
                    Picker("Date Format", selection: $dateFormatRaw) {
                        ForEach(DateFormatOption.allCases) { f in
                            Text(f.displayName).tag(f.rawValue)
                        }
                    }
                }

                Section("Navigation") {
                    Toggle("Hide navigation bar", isOn: $hideNavBarWhenSwipeOn)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
