import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupID = "group.com.seunghuntak.Tasket"

    static var container: ModelContainer = {
        let fm = FileManager.default
        guard let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group container not found. Check App Groups capability on BOTH targets.")
        }

        let storeURL = groupURL.appendingPathComponent("Tasket.store")
        let schema = Schema([TaskItem.self, MonthNote.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}
