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

        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now) ?? now }

        // ── Peptide 1 — Retatrutide ────────────────────────────────────────
        // 5 mg in 1 mL → 5,000 mcg/mL.
        // Titrating up: 250 → 250 → 500 → 500 → 750 mcg (2,250 mcg used → 55% full).
        // Last dose 750 mcg → ~3 doses remaining shown on gauge.
        let reta = Peptide(
            name: "Retatrutide",
            defaultDoseMcg: 500,
            scheduleType: .fixedRecurring,
            frequency: .weekly,
            scheduledTime: cal.date(bySettingHour: 8, minute: 0, second: 0, of: now),
            scheduleDays: [1],
            notes: nil
        )
        let retaVial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 1.0,
            dateMixed: daysAgo(14),
            expiryDays: 30,
            totalVolumeUsedML: 0.45  // 2250mcg / 5000 mcg·mL⁻¹
        )
        retaVial.peptide = reta
        context.insert(reta)
        context.insert(retaVial)

        let retaDoseHistory: [(Int, Double, InjectionSite)] = [
            (14, 250, .abdomen),
            (10, 250, .abdomen),
            (7,  500, .thighLeft),
            (3,  500, .thighRight),
            (1,  750, .abdomen),
        ]
        for (day, mcg, site) in retaDoseHistory {
            let d = DoseEntry(
                timestamp: daysAgo(day),
                doseMcg: mcg,
                unitsInjectedML: mcg / 5000,
                injectionSite: site,
                notes: nil
            )
            d.peptide = reta
            d.vial = retaVial
            context.insert(d)
        }

        // ── Peptide 2 — Selank ────────────────────────────────────────────
        // 10 mg in 1 mL → 10,000 mcg/mL.
        // Steady 500 mcg × 5 doses = 2,500 mcg used → 75% full.
        // ~15 doses remaining at 500 mcg.
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
            waterVolumeML: 1.0,
            dateMixed: daysAgo(5),
            expiryDays: 30,
            totalVolumeUsedML: 0.25  // 2500mcg / 10000 mcg·mL⁻¹
        )
        selankVial.peptide = selank
        context.insert(selank)
        context.insert(selankVial)

        let selankSites: [InjectionSite] = [.thighLeft, .thighRight, .abdomen, .thighLeft, .thighRight]
        for (i, site) in selankSites.enumerated() {
            let d = DoseEntry(
                timestamp: daysAgo(i + 1),
                doseMcg: 500,
                unitsInjectedML: 0.05,
                injectionSite: site,
                notes: nil
            )
            d.peptide = selank
            d.vial = selankVial
            context.insert(d)
        }

        try? context.save()
    }
}
#endif
