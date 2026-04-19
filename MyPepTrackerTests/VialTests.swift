import Testing
import Foundation
@testable import MyPepTracker

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
        let mixed = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: mixed,
            expiryDays: 30
        )
        #expect(vial.isExpired == true)
    }

    @Test func isNotExpiredWhenFresh() {
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: Date(),
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

    @Test func remainingDosesUsesActualAverageWhenHistoryExists() {
        // User's actual doses: 0.1 mL and 0.3 mL → avg 0.2 mL.
        // Total used = 0.4 mL, remaining = 1.6 mL. 1.6 / 0.2 = 8 doses.
        let peptide = Peptide(
            name: "Test",
            defaultDoseMcg: 1000,   // default would project only 4 remaining — precision matters
            scheduleType: .fixedRecurring,
            frequency: .daily
        )
        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        vial.totalVolumeUsedML = 0.4

        let d1 = DoseEntry(timestamp: Date(), doseMcg: 250, unitsInjectedML: 0.1)
        let d2 = DoseEntry(timestamp: Date(), doseMcg: 750, unitsInjectedML: 0.3)
        vial.doseEntries = [d1, d2]

        #expect(vial.estimatedRemainingDoses(forPeptide: peptide) == 8)
    }

    @Test func remainingDosesIgnoresZeroVolumeEntries() {
        // Zero-volume entries (logged when no active vial) must not drag the average.
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

        // Average should be 0.2 mL (only the valid dose), so 2.0 / 0.2 = 10.
        #expect(vial.estimatedRemainingDoses(forPeptide: peptide) == 10)
    }
}
