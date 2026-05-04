import Foundation
import SwiftData
@testable import MyPepTracker

// MARK: - Shared Test Infrastructure

/// Creates an in-memory SwiftData container for isolated tests.
func makeInMemoryContext() throws -> ModelContext {
    let schema = Schema([Peptide.self, Vial.self, DoseEntry.self, BodyMeasurement.self, BodyMetricGoal.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return ModelContext(container)
}

// MARK: - Fixed Date Provider

struct FixedDateProvider: DateProvider {
    let fixedDate: Date
    func now() -> Date { fixedDate }
}

/// Swaps the global date provider for the duration of a test.
/// Always call `DateProviderRegistry.reset()` in tear-down to avoid leaking
/// fixed dates between tests.
func setFixedDate(_ date: Date) {
    DateProviderRegistry.current = FixedDateProvider(fixedDate: date)
}
