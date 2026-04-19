import SwiftUI
import SwiftData

@main
struct MyPepTrackerApp: App {
    private let container: ModelContainer = {
        let schema = Schema([Peptide.self, Vial.self, DoseEntry.self, BodyMeasurement.self])

        #if DEBUG
        // Screenshot mode: isolated in-memory store with deterministic seed data.
        if ProcessInfo.processInfo.arguments.contains("-screenshotMode") {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            let c = try! ModelContainer(for: schema, configurations: config)
            DemoSeed.populate(into: c.mainContext)
            return c
        }
        #endif

        let config = ModelConfiguration()
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: config)
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await setupNotifications()
                }
        }
        .modelContainer(container)
    }

    private func setupNotifications() async {
        let manager = NotificationManager.shared
        let granted = await manager.requestPermission()
        if granted {
            manager.registerCategories()
        }
    }
}
