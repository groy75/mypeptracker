import Testing
@testable import MyPepTracker

@Suite("ConcentrationCalculator")
struct ConcentrationCalculatorTests {

    // MARK: - Parameterized concentration tests

    @Test(arguments: [
        (5.0, 2.0, 2500.0),   // standard reconstitution
        (10.0, 1.0, 10000.0), // high concentration
        (2.0, 3.0, 666.6666666666666), // fractional
        (1.0, 1.0, 1000.0),   // 1:1
    ])
    func concentrationMcgPerML(peptideMg: Double, waterML: Double, expected: Double) {
        let result = ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: peptideMg,
            waterVolumeML: waterML
        )
        #expect(result == expected)
    }

    @Test(arguments: [
        (250.0, 2500.0, 0.1),
        (500.0, 2500.0, 0.2),
        (1000.0, 5000.0, 0.2),
        (125.0, 2500.0, 0.05),
    ])
    func volumeMLForDose(doseMcg: Double, concentration: Double, expected: Double) {
        let result = ConcentrationCalculator.volumeMLForDose(
            doseMcg: doseMcg,
            concentrationMcgPerML: concentration
        )
        #expect(result == expected)
    }

    @Test(arguments: [
        (0.1, 10.0),
        (0.2, 20.0),
        (1.0, 100.0),
        (0.05, 5.0),
    ])
    func insulinUnits(ml: Double, expected: Double) {
        let result = ConcentrationCalculator.insulinUnits(fromML: ml)
        #expect(result == expected)
    }

    // MARK: - Boundary cases

    @Test func concentrationWithZeroWaterReturnsInfinity() {
        let result = ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: 5.0,
            waterVolumeML: 0.0
        )
        #expect(result.isInfinite)
    }

    @Test func volumeForDoseWithZeroConcentrationReturnsInfinity() {
        let result = ConcentrationCalculator.volumeMLForDose(
            doseMcg: 250.0,
            concentrationMcgPerML: 0.0
        )
        #expect(result.isInfinite)
    }

    @Test func insulinUnitsForZeroMLReturnsZero() {
        let result = ConcentrationCalculator.insulinUnits(fromML: 0.0)
        #expect(result == 0.0)
    }

    @Test func remainingDosesBasic() {
        let result = ConcentrationCalculator.estimatedRemainingDoses(
            totalVolumeML: 2.0,
            usedVolumeML: 0.3,
            doseMcg: 250.0,
            concentrationMcgPerML: 2500.0
        )
        #expect(result == 17)
    }

    @Test func remainingDosesWithZeroDoseReturnsZero() {
        let result = ConcentrationCalculator.estimatedRemainingDoses(
            totalVolumeML: 2.0,
            usedVolumeML: 0.0,
            doseMcg: 0.0,
            concentrationMcgPerML: 2500.0
        )
        #expect(result == 0)
    }

    @Test func remainingDosesWhenFullyUsedReturnsZero() {
        let result = ConcentrationCalculator.estimatedRemainingDoses(
            totalVolumeML: 2.0,
            usedVolumeML: 2.0,
            doseMcg: 250.0,
            concentrationMcgPerML: 2500.0
        )
        #expect(result == 0)
    }
}
