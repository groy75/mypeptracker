import Foundation
import SwiftData

@Model
final class Vial {
    var peptideAmountMg: Double
    var waterVolumeML: Double
    var dateMixed: Date
    var expiryDays: Int
    var totalVolumeUsedML: Double
    var isActive: Bool
    var spoiledAt: Date?

    var peptide: Peptide?

    @Relationship(deleteRule: .cascade, inverse: \DoseEntry.vial)
    var doseEntries: [DoseEntry] = []

    var concentrationMcgPerML: Double {
        ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: peptideAmountMg,
            waterVolumeML: waterVolumeML
        )
    }

    /// Returns the expiry date, or `dateMixed` if calendar arithmetic fails
    /// (e.g. near DST boundaries). Previously force-unwrapped and could crash.
    var expiryDate: Date {
        Calendar.current.date(byAdding: .day, value: expiryDays, to: dateMixed) ?? dateMixed
    }

    var isExpired: Bool {
        expiryDate < DateProviderRegistry.now()
    }

    var isSpoiled: Bool { spoiledAt != nil }

    var remainingVolumeML: Double {
        waterVolumeML - totalVolumeUsedML
    }

    var totalMcgUsed: Double {
        doseEntries.reduce(0) { $0 + $1.doseMcg }
    }

    var remainingMcg: Double {
        max(0, peptideAmountMg * 1000 - totalMcgUsed)
    }

    /// Fraction of total mcg still remaining in the vial (0.0…1.0).
    var fillFraction: Double {
        let total = peptideAmountMg * 1000
        guard total > 0 else { return 0 }
        return min(1.0, remainingMcg / total)
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: DateProviderRegistry.now(), to: expiryDate).day ?? 0
    }

    // Uses doseMcg (preserved on each entry) so it stays correct after concentration edits.
    func estimatedRemainingDoses(forDoseMcg doseMcg: Double) -> Int {
        guard doseMcg > 0, doseMcg.isFinite else { return 0 }
        return safeInt(remainingMcg / doseMcg)
    }

    /// The most recent logged dose on this vial, nil if no doses yet.
    var lastDoseMcg: Double? {
        doseEntries
            .sorted { $0.timestamp > $1.timestamp }
            .first
            .map(\.doseMcg)
    }

    /// Remaining doses projected using the last logged dose as the per-dose size.
    /// Falls back to the peptide's default when no history exists yet.
    func estimatedRemainingDoses(forPeptide peptide: Peptide) -> Int {
        let basis = lastDoseMcg ?? peptide.defaultDoseMcg
        return estimatedRemainingDoses(forDoseMcg: basis)
    }

    init(
        peptideAmountMg: Double,
        waterVolumeML: Double,
        dateMixed: Date = Date(),
        expiryDays: Int = 30,
        totalVolumeUsedML: Double = 0,
        isActive: Bool = true
    ) {
        self.peptideAmountMg = peptideAmountMg
        self.waterVolumeML = waterVolumeML
        self.dateMixed = dateMixed
        self.expiryDays = expiryDays
        self.totalVolumeUsedML = totalVolumeUsedML
        self.isActive = isActive
    }
}
