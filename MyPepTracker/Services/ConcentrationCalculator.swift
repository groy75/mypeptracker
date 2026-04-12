import Foundation

enum ConcentrationCalculator {
    static func concentrationMcgPerML(peptideAmountMg: Double, waterVolumeML: Double) -> Double {
        (peptideAmountMg * 1000.0) / waterVolumeML
    }

    static func volumeMLForDose(doseMcg: Double, concentrationMcgPerML: Double) -> Double {
        doseMcg / concentrationMcgPerML
    }

    static func insulinUnits(fromML ml: Double) -> Double {
        ml * 100.0
    }

    static func estimatedRemainingDoses(
        totalVolumeML: Double,
        usedVolumeML: Double,
        doseMcg: Double,
        concentrationMcgPerML: Double
    ) -> Int {
        let remainingML = totalVolumeML - usedVolumeML
        let mlPerDose = volumeMLForDose(doseMcg: doseMcg, concentrationMcgPerML: concentrationMcgPerML)
        return Int(remainingML / mlPerDose)
    }
}
