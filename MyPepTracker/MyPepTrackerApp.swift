import SwiftUI
import SwiftData

@main
struct MyPepTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Peptide.self, Vial.self, DoseEntry.self])
    }
}
