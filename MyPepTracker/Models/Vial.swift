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

    var expiryDate: Date {
        Calendar.current.date(byAdding: .day, value: expiryDays, to: dateMixed)!
    }

    var isExpired: Bool {
        expiryDate < Date()
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

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }

    // Uses doseMcg (preserved on each entry) so it stays correct after concentration edits.
    func estimatedRemainingDoses(forDoseMcg doseMcg: Double) -> Int {
        guard doseMcg > 0 else { return 0 }
        return Int(remainingMcg / doseMcg)
    }

    /// Remaining doses projected from the actual dose history of this vial.
    /// Uses the average logged doseMcg; falls back to the peptide's default when no history.
    func estimatedRemainingDoses(forPeptide peptide: Peptide) -> Int {
        let loggedMcg = doseEntries.map(\.doseMcg).filter { $0 > 0 }
        guard !loggedMcg.isEmpty else {
            return estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
        }
        let avgDoseMcg = loggedMcg.reduce(0, +) / Double(loggedMcg.count)
        return estimatedRemainingDoses(forDoseMcg: avgDoseMcg)
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
