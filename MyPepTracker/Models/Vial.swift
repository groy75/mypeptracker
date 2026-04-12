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

    var remainingVolumeML: Double {
        waterVolumeML - totalVolumeUsedML
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }

    func estimatedRemainingDoses(forDoseMcg doseMcg: Double) -> Int {
        ConcentrationCalculator.estimatedRemainingDoses(
            totalVolumeML: waterVolumeML,
            usedVolumeML: totalVolumeUsedML,
            doseMcg: doseMcg,
            concentrationMcgPerML: concentrationMcgPerML
        )
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
