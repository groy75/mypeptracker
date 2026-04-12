import SwiftUI
import SwiftData

@main
struct MyPepTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await setupNotifications()
                }
        }
        .modelContainer(for: [Peptide.self, Vial.self, DoseEntry.self])
    }

    private func setupNotifications() async {
        let manager = NotificationManager.shared
        let granted = await manager.requestPermission()
        if granted {
            manager.registerCategories()
        }
    }
}
