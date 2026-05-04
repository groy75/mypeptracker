import Foundation
import SwiftData
import UIKit

/// Encapsulates the complete dose-logging workflow:
/// 1. Creates a `DoseEntry`
/// 2. Updates vial volume tracking
/// 3. Schedules notifications
/// 4. Triggers haptic feedback
///
/// This keeps `LogDoseSheet` focused on UI binding only.
@MainActor
struct DoseLoggingService {
    private let notificationManager: NotificationManager
    private let hapticGenerator: UINotificationFeedbackGenerator

    init(
        notificationManager: NotificationManager = .shared,
        hapticGenerator: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    ) {
        self.notificationManager = notificationManager
        self.hapticGenerator = hapticGenerator
    }

    /// Logs a dose and returns a human-readable confirmation message.
    /// - Parameters:
    ///   - peptide: The peptide being dosed
    ///   - doseMcg: Microgram amount
    ///   - doseDate: Timestamp for the entry
    ///   - injectionSite: Optional body location
    ///   - notes: Optional free-text notes
    ///   - context: SwiftData model context for persistence
    /// - Returns: Confirmation message (e.g. "Logged 250mcg of BPC-157")
    @discardableResult
    func logDose(
        peptide: Peptide,
        doseMcg: Double,
        doseDate: Date,
        injectionSite: InjectionSite?,
        notes: String?,
        into context: ModelContext
    ) -> String {
        let vial = peptide.activeVial

        let volumeML: Double
        if let vial {
            volumeML = ConcentrationCalculator.volumeMLForDose(
                doseMcg: doseMcg,
                concentrationMcgPerML: vial.concentrationMcgPerML
            )
        } else {
            volumeML = 0
        }

        let entry = DoseEntry(
            timestamp: doseDate,
            doseMcg: doseMcg,
            unitsInjectedML: volumeML,
            injectionSite: injectionSite,
            notes: notes
        )
        entry.peptide = peptide
        entry.vial = vial

        if let vial {
            vial.totalVolumeUsedML += volumeML
            let remaining = vial.estimatedRemainingDoses(forPeptide: peptide)
            notificationManager.scheduleVialLowWarning(for: peptide, remainingDoses: remaining)
        }

        context.insert(entry)

        notificationManager.scheduleDoseReminder(for: peptide)
        notificationManager.scheduleOverdueReminder(for: peptide)

        hapticGenerator.notificationOccurred(.success)

        return "Logged \(Int(doseMcg))mcg of \(peptide.name)"
    }
}
