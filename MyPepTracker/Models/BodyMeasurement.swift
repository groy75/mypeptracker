import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var id: UUID = UUID()
    var timestamp: Date
    var metric: BodyMetric
    /// Always stored in SI (kg / cm / %). Display layer converts per user preference.
    var value: Double
    var notes: String?

    init(
        metric: BodyMetric,
        value: Double,
        timestamp: Date = Date(),
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.metric = metric
        self.value = value
        self.notes = notes
    }
}
