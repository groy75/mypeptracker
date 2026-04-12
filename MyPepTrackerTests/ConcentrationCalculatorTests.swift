import Testing
@testable import MyPepTracker

struct ConcentrationCalculatorTests {
    @Test func concentrationFromStandardReconstitution() {
        let result = ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0
        )
        #expect(result == 2500.0)
    }

    @Test func concentrationFromHighConcentration() {
        let result = ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: 10.0,
            waterVolumeML: 1.0
        )
        #expect(result == 10000.0)
    }

    @Test func unitsForDose() {
        let result = ConcentrationCalculator.volumeMLForDose(
            doseMcg: 250.0,
            concentrationMcgPerML: 2500.0
        )
        #expect(result == 0.1)
    }

    @Test func insulinUnitsFromML() {
        let result = ConcentrationCalculator.insulinUnits(fromML: 0.1)
        #expect(result == 10.0)
    }

    @Test func estimatedRemainingDoses() {
        let result = ConcentrationCalculator.estimatedRemainingDoses(
            totalVolumeML: 2.0,
            usedVolumeML: 0.3,
            doseMcg: 250.0,
            concentrationMcgPerML: 2500.0
        )
        #expect(result == 17)
    }
}
