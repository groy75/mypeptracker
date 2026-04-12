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
}
