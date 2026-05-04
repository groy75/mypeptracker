import Testing
import Foundation
@testable import MyPepTracker

@Suite("Peptide")
struct PeptideTests {

    @Test func activeVialReturnsFirstNonExpiredActiveVial() {
        let peptide = Peptide(name: "BPC-157", defaultDoseMcg: 250, scheduleType: .fixedRecurring, frequency: .daily)
        let fresh = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0, isActive: true)
        let expired = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0, dateMixed: Calendar.current.date(byAdding: .day, value: -40, to: Date())!, isActive: true)
        let inactive = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0, isActive: false)
        peptide.vials = [expired, inactive, fresh]

        #expect(peptide.activeVial === fresh)
    }

    @Test func activeVialReturnsNilWhenAllExpired() {
        let peptide = Peptide(name: "BPC-157", defaultDoseMcg: 250, scheduleType: .fixedRecurring, frequency: .daily)
        let expired = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0, dateMixed: Calendar.current.date(byAdding: .day, value: -40, to: Date())!, isActive: true)
        peptide.vials = [expired]

        #expect(peptide.activeVial == nil)
    }

    @Test func lastDoseReturnsMostRecent() {
        let peptide = Peptide(name: "BPC-157", defaultDoseMcg: 250, scheduleType: .fixedRecurring, frequency: .daily)
        let old = DoseEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), doseMcg: 250, unitsInjectedML: 0.1)
        let recent = DoseEntry(timestamp: Date(timeIntervalSince1970: 1_800_000_000), doseMcg: 300, unitsInjectedML: 0.12)
        peptide.doseEntries = [old, recent]

        #expect(peptide.lastDose?.doseMcg == 300)
    }

    @Test func lastDoseReturnsNilWithNoEntries() {
        let peptide = Peptide(name: "BPC-157", defaultDoseMcg: 250, scheduleType: .fixedRecurring, frequency: .daily)
        #expect(peptide.lastDose == nil)
    }

    @Test func cycleEndDate() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let peptide = Peptide(
            name: "BPC-157",
            defaultDoseMcg: 250,
            scheduleType: .fixedRecurring,
            frequency: .daily,
            cycleStartDate: start,
            cycleLengthWeeks: 8
        )

        let expected = calendar.date(from: DateComponents(year: 2024, month: 2, day: 26))!
        #expect(peptide.cycleEndDate == expected)
    }

    @Test func cycleEndDateReturnsNilWithoutStart() {
        let peptide = Peptide(name: "BPC-157", defaultDoseMcg: 250, scheduleType: .fixedRecurring, frequency: .daily)
        #expect(peptide.cycleEndDate == nil)
    }

    @Test func cycleProgressAtStart() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let peptide = Peptide(
            name: "BPC-157",
            defaultDoseMcg: 250,
            scheduleType: .fixedRecurring,
            frequency: .daily,
            cycleStartDate: start,
            cycleLengthWeeks: 4
        )
        #expect(peptide.cycleProgress == 0.0)
    }

    @Test func cycleProgressAtMidpoint() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let peptide = Peptide(
            name: "BPC-157",
            defaultDoseMcg: 250,
            scheduleType: .fixedRecurring,
            frequency: .daily,
            cycleStartDate: start,
            cycleLengthWeeks: 4
        )
        // 14 days elapsed / 28 days total = 0.5
        #expect(peptide.cycleProgress! >= 0.49 && peptide.cycleProgress! <= 0.51)
    }

    @Test func cycleProgressClampedToOne() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let peptide = Peptide(
            name: "BPC-157",
            defaultDoseMcg: 250,
            scheduleType: .fixedRecurring,
            frequency: .daily,
            cycleStartDate: start,
            cycleLengthWeeks: 4
        )
        #expect(peptide.cycleProgress == 1.0)
    }

    @Test func cycleDaysRemaining() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let peptide = Peptide(
            name: "BPC-157",
            defaultDoseMcg: 250,
            scheduleType: .fixedRecurring,
            frequency: .daily,
            cycleStartDate: start,
            cycleLengthWeeks: 4
        )
        // 28 days total - 14 elapsed = 14 remaining
        #expect(peptide.cycleDaysRemaining == 14)
    }

    @Test func cycleDaysRemainingClampedToZero() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let peptide = Peptide(
            name: "BPC-157",
            defaultDoseMcg: 250,
            scheduleType: .fixedRecurring,
            frequency: .daily,
            cycleStartDate: start,
            cycleLengthWeeks: 4
        )
        #expect(peptide.cycleDaysRemaining == 0)
    }
}
