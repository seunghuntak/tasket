import SwiftUI
import SwiftData

@main
struct TasketApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(SharedModelContainer.container)    }
}
