import Foundation
import SwiftData

/// User-set target for a single BodyMetric. At most one goal per metric —
/// enforced at save time in `SetGoalSheet` (upsert semantics). Values are SI
/// (kg / cm / %); display layer converts per user preference.
@Model
final class BodyMetricGoal {
    var id: UUID = UUID()
    var metric: BodyMetric
    var startValue: Double
    var startDate: Date
    var targetValue: Double
    /// Optional — a goal can be open-ended ("get to X by someday").
    var targetDate: Date?
    var createdAt: Date

    init(
        metric: BodyMetric,
        startValue: Double,
        targetValue: Double,
        startDate: Date = Date(),
        targetDate: Date? = nil
    ) {
        self.metric = metric
        self.startValue = startValue
        self.startDate = startDate
        self.targetValue = targetValue
        self.targetDate = targetDate
        self.createdAt = Date()
    }

    /// Direction the user is moving: derived from start → target.
    /// `steady` covers the degenerate case where target equals start
    /// (not useful but we don't crash on it).
    enum Direction: Sendable {
        case increase
        case decrease
        case steady
    }

    var direction: Direction {
        if targetValue > startValue { return .increase }
        if targetValue < startValue { return .decrease }
        return .steady
    }

    /// Progress in [0, ∞). ≥1.0 means the goal has been met or exceeded
    /// (overshoot is useful information, so we don't clamp to 1).
    /// Returns nil for `.steady` goals (undefined).
    func progress(currentValue: Double) -> Double? {
        switch direction {
        case .steady:
            return nil
        case .increase:
            let span = targetValue - startValue
            return (currentValue - startValue) / span
        case .decrease:
            let span = startValue - targetValue
            return (startValue - currentValue) / span
        }
    }

    /// Convenience: progress clamped to [0, 1] for progress-bar rendering.
    func progressFractionForDisplay(currentValue: Double) -> Double {
        guard let p = progress(currentValue: currentValue) else { return 0 }
        return min(max(p, 0), 1)
    }

    func isComplete(currentValue: Double) -> Bool {
        guard let p = progress(currentValue: currentValue) else { return false }
        return p >= 1.0
    }
}
