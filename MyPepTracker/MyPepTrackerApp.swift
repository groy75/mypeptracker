import SwiftUI
import SwiftData

@main
struct MyPepTrackerApp: App {
    /// Shared container reference for services that need context access
    /// (e.g. WidgetSyncService from NotificationManager).
    static var sharedContainer: ModelContainer?

    private let container: ModelContainer = {
        let schema = Schema([Peptide.self, Vial.self, DoseEntry.self, BodyMeasurement.self, BodyMetricGoal.self])

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

        let config = ModelConfiguration(
            cloudKitDatabase: .automatic
        )
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: config)
        Self.sharedContainer = container
        return container
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
        await runNotificationIDMigrationIfNeeded()
    }

    // Runs exactly once per install after upgrading to v1.4.0+ where
    // notification identifiers switched from peptide-name-keyed to
    // `Peptide.notificationID`-keyed. Purges any legacy pending requests
    // (which would otherwise fire as ghosts) and re-schedules from current state.
    private static let notificationIDMigrationKey = "notificationID_uuid_migration_v1"

    @MainActor
    private func runNotificationIDMigrationIfNeeded() async {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.notificationIDMigrationKey) else { return }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Peptide>()
        guard let peptides = try? context.fetch(descriptor) else { return }

        NotificationManager.shared.wipePendingAndReschedule(peptides: peptides)
        defaults.set(true, forKey: Self.notificationIDMigrationKey)
    }
}
