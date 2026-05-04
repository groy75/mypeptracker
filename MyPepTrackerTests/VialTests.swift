import Testing
import Foundation
@testable import MyPepTracker

@Suite("Vial")
struct VialTests {
    @Test func expiryDateCalculation() {
        let mixed = Date(timeIntervalSince1970: 1_700_000_000)
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: mixed,
            expiryDays: 30
        )
        let expected = Calendar.current.date(byAdding: .day, value: 30, to: mixed)!
        #expect(vial.expiryDate == expected)
    }

    @Test func isExpiredWhenPastExpiry() {
        let mixed = Calendar.current.date(byAdding: .day, value: -31, to: DateProviderRegistry.now())!
        setFixedDate(DateProviderRegistry.now())
        defer { DateProviderRegistry.reset() }
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: mixed,
            expiryDays: 30
        )
        #expect(vial.isExpired == true)
    }

    @Test func isNotExpiredWhenFresh() {
        setFixedDate(DateProviderRegistry.now())
        defer { DateProviderRegistry.reset() }
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: DateProviderRegistry.now(),
            expiryDays: 30
        )
        #expect(vial.isExpired == false)
    }

    @Test func concentrationAutoCalculated() {
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: Date(),
            expiryDays: 30
        )
        #expect(vial.concentrationMcgPerML == 2500.0)
    }

    @Test func remainingVolumeAfterUsage() {
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: Date(),
            expiryDays: 30
        )
        vial.totalVolumeUsedML = 0.5
        #expect(vial.remainingVolumeML == 1.5)
    }

    @Test func remainingDosesFallsBackToDefaultWithoutHistory() {
        // 5mg in 2mL → 2500 mcg/mL. 500 mcg default dose → 0.2 mL per dose.
        // Remaining volume = 2.0 mL → 10 doses.
        let peptide = Peptide(
            name: "Test",
            defaultDoseMcg: 500,
            scheduleType: .fixedRecurring,
            frequency: .daily
        )
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        #expect(vial.estimatedRemainingDoses(forPeptide: peptide) == 10)
    }

    @Test func remainingDosesUsesLastDoseWhenHistoryExists() {
        // Uses lastDoseMcg (not average). Last dose = 750 mcg.
        // 5mg in 2mL → 2500 mcg/mL. Total mcg used = 250 + 750 = 1000.
        // Remaining mcg = 5000 - 1000 = 4000. 4000 / 750 = 5.33 → 5 doses.
        let peptide = Peptide(
            name: "Test",
            defaultDoseMcg: 1000,
            scheduleType: .fixedRecurring,
            frequency: .daily
        )
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        vial.totalVolumeUsedML = 0.4

        let d1 = DoseEntry(timestamp: Date(), doseMcg: 250, unitsInjectedML: 0.1)
        let d2 = DoseEntry(timestamp: Date(), doseMcg: 750, unitsInjectedML: 0.3)
        vial.doseEntries = [d1, d2]

        #expect(vial.estimatedRemainingDoses(forPeptide: peptide) == 5)
    }

    @Test func remainingDosesIgnoresZeroVolumeEntries() {
        // Uses lastDoseMcg. Last dose = 500 mcg (phantom has 0 volume but 500 mcg).
        // 5mg in 2mL → 2500 mcg/mL. Total mcg used = 500 + 500 = 1000.
        // Remaining mcg = 5000 - 1000 = 4000. 4000 / 500 = 8 doses.
        let peptide = Peptide(
            name: "Test",
            defaultDoseMcg: 500,
            scheduleType: .fixedRecurring,
            frequency: .daily
        )
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        let valid = DoseEntry(timestamp: Date(), doseMcg: 500, unitsInjectedML: 0.2)
        let phantom = DoseEntry(timestamp: Date(), doseMcg: 500, unitsInjectedML: 0)
        vial.doseEntries = [valid, phantom]

        #expect(vial.estimatedRemainingDoses(forPeptide: peptide) == 8)
    }

    // MARK: - fillFraction

    @Test func fillFractionFull() {
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        #expect(vial.fillFraction == 1.0)
    }

    @Test func fillFractionHalfUsed() {
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        let dose = DoseEntry(doseMcg: 2500, unitsInjectedML: 1.0)
        vial.doseEntries = [dose]
        // 2500 mcg used out of 5000 mcg → 0.5 remaining
        #expect(vial.fillFraction == 0.5)
    }

    @Test func fillFractionEmpty() {
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        let dose = DoseEntry(doseMcg: 5000, unitsInjectedML: 2.0)
        vial.doseEntries = [dose]
        #expect(vial.fillFraction == 0.0)
    }

    @Test func fillFractionClampedToZero() {
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        // Over-use (shouldn't happen, but math should clamp)
        let dose = DoseEntry(doseMcg: 6000, unitsInjectedML: 2.5)
        vial.doseEntries = [dose]
        #expect(vial.fillFraction == 0.0)
    }

    @Test func fillFractionWithZeroPeptideAmount() {
        let vial = Vial(peptideAmountMg: 0.0, waterVolumeML: 2.0)
        #expect(vial.fillFraction == 0.0)
    }
}
