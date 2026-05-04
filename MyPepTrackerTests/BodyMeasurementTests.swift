import Testing
import Foundation
import SwiftData
@testable import MyPepTracker

@MainActor
struct BodyMeasurementTests {
    @Test func storesValueInSI() {
        let entry = BodyMeasurement(metric: .weight, value: 80.5)
        #expect(entry.metric == .weight)
        #expect(entry.value == 80.5)
        #expect(entry.notes == nil)
    }

    @Test func persistsAndQueriesSortedByDate() throws {
        let ctx = try makeInMemoryContext()
        let base = Date()
        let older = BodyMeasurement(metric: .weight, value: 82.0, timestamp: base.addingTimeInterval(-7 * 86_400))
        let newer = BodyMeasurement(metric: .weight, value: 80.5, timestamp: base)
        ctx.insert(older)
        ctx.insert(newer)
        try ctx.save()

        let descending = try ctx.fetch(
            FetchDescriptor<BodyMeasurement>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        )
        #expect(descending.count == 2)
        #expect(descending.first?.timestamp == newer.timestamp)
    }

    @Test(arguments: [
        (80.0,  BodyMetric.Unit.kilograms,   false, 80.0),
        (80.0,  BodyMetric.Unit.kilograms,   true,  176.36980974), // kg → lb
        (90.0,  BodyMetric.Unit.centimeters, false, 90.0),
        (90.0,  BodyMetric.Unit.centimeters, true,  35.4330708),   // cm → in
        (18.5,  BodyMetric.Unit.percent,     false, 18.5),
        (18.5,  BodyMetric.Unit.percent,     true,  18.5),
    ])
    func displayConversion(siValue: Double, unit: BodyMetric.Unit, imperial: Bool, expected: Double) {
        let out = BodyMetricFormat.display(siValue, unit: unit, imperial: imperial)
        #expect(abs(out - expected) < 0.001)
    }

    @Test func storageRoundTripImperialInputKeepsOriginal() {
        // User enters 176.37 lb with imperial preference → stored in kg → displayed back in lb.
        let input = 176.3698
        let stored = BodyMetricFormat.storage(input, unit: .kilograms, imperial: true)
        let shown = BodyMetricFormat.display(stored, unit: .kilograms, imperial: true)
        #expect(abs(shown - input) < 0.001)
        // And stored value should be approximately 80 kg.
        #expect(abs(stored - 80.0) < 0.001)
    }

    @Test func allMetricsHaveDistinctDisplayNames() {
        let names = Set(BodyMetric.allCases.map(\.displayName))
        #expect(names.count == BodyMetric.allCases.count)
    }

    @Test func weightAndBodyFatHaveNoBodyPosition() {
        #expect(BodyMetric.weight.bodyPosition == nil)
        #expect(BodyMetric.bodyFatPercent.bodyPosition == nil)
    }

    @Test func allLengthMetricsHaveBodyPosition() {
        let length: [BodyMetric] = [
            .waist, .neck, .chest, .backWidth,
            .bicepLeft, .bicepRight, .thighLeft, .thighRight
        ]
        for m in length {
            #expect(m.bodyPosition != nil, "\(m.displayName) should have a body position")
        }
    }
}
