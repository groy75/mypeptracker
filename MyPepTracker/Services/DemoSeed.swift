#if DEBUG
import Foundation
import SwiftData

/// Deterministic seed data for App Store screenshots and UI tests.
/// Activated only when the app launches with `-screenshotMode`, via
/// `MyPepTrackerApp`. Never runs in Release builds.
enum DemoSeed {
    static func populate(into context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        // Peptide 1 — Retatrutide (fixed schedule, morning)
        let reta = Peptide(
            name: "Retatrutide",
            defaultDoseMcg: 500,
            scheduleType: .fixedRecurring,
            frequency: .weekly,
            scheduledTime: cal.date(bySettingHour: 8, minute: 0, second: 0, of: now),
            scheduleDays: [1],   // Sunday
            notes: nil
        )
        let retaVial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: cal.date(byAdding: .day, value: -7, to: now) ?? now,
            expiryDays: 30,
            totalVolumeUsedML: 0.2
        )
        retaVial.peptide = reta
        context.insert(reta)
        context.insert(retaVial)

        let retaDose = DoseEntry(
            timestamp: cal.date(byAdding: .day, value: -7, to: now) ?? now,
            doseMcg: 500,
            unitsInjectedML: 0.2,
            injectionSite: .abdomen,
            notes: nil
        )
        retaDose.peptide = reta
        retaDose.vial = retaVial
        context.insert(retaDose)

        // Peptide 2 — Selank (after-dose cadence)
        let selank = Peptide(
            name: "Selank",
            defaultDoseMcg: 500,
            scheduleType: .afterDose,
            frequency: .daily,
            scheduledTime: nil,
            scheduleDays: nil,
            notes: "Intranasal, morning routine."
        )
        let selankVial = Vial(
            peptideAmountMg: 10.0,
            waterVolumeML: 2.0,
            dateMixed: cal.date(byAdding: .day, value: -3, to: now) ?? now,
            expiryDays: 30,
            totalVolumeUsedML: 0.3
        )
        selankVial.peptide = selank
        context.insert(selank)
        context.insert(selankVial)

        let selankDoses: [(Int, InjectionSite)] = [
            (1, .thighLeft), (2, .thighRight), (3, .abdomen)
        ]
        for (daysAgo, site) in selankDoses {
            let dose = DoseEntry(
                timestamp: cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now,
                doseMcg: 500,
                unitsInjectedML: 0.1,
                injectionSite: site,
                notes: nil
            )
            dose.peptide = selank
            dose.vial = selankVial
            context.insert(dose)
        }

        try? context.save()
    }
}
#endif
