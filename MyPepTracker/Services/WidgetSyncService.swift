import Foundation
import WidgetKit

/// Syncs peptide scheduling data to shared UserDefaults so the Home Screen widget
/// can display next-dose info without direct SwiftData access.
struct WidgetSyncService {
    static let shared = WidgetSyncService()
    private let suiteName = "group.com.greg.roy.MyPepTracker"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// Updates widget data with the next upcoming dose across all peptides.
    func syncNextDose(peptides: [Peptide]) {
        let now = DateProviderRegistry.now()
        var bestPeptide: String?
        var bestInterval: TimeInterval = .infinity

        for peptide in peptides where peptide.isActive {
            guard let next = NotificationManager.nextDoseDate(
                scheduleType: peptide.scheduleType,
                frequency: peptide.frequency,
                lastDoseTimestamp: peptide.lastDose?.timestamp,
                scheduledTime: peptide.scheduledTime,
                scheduleDays: peptide.scheduleDays
            ) else { continue }

            let interval = next.timeIntervalSince(now)
            if interval > 0, interval < bestInterval {
                bestInterval = interval
                bestPeptide = peptide.name
            }
        }

        let d = defaults
        d?.set(bestPeptide ?? "No doses scheduled", forKey: "widget_nextDosePeptide")
        let minutes = bestInterval.isFinite ? Int(bestInterval / 60) : 0
        d?.set(minutes, forKey: "widget_nextDoseMinutes")
        d?.set(peptides.filter(\.isActive).reduce(0) { $0 + $1.vials.filter(\.isActive).count }, forKey: "widget_activeVials")

        WidgetCenter.shared.reloadTimelines(ofKind: "MyPepTrackerWidget")
    }
}
