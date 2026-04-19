import Testing
import Foundation
import SwiftData
@testable import MyPepTracker

@MainActor
struct BodyMetricGoalTests {
    @Test func decreaseDirection() {
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        #expect(goal.direction == .decrease)
    }

    @Test func increaseDirection() {
        let goal = BodyMetricGoal(metric: .bicepLeft, startValue: 35, targetValue: 40)
        #expect(goal.direction == .increase)
    }

    @Test func steadyDirection() {
        let goal = BodyMetricGoal(metric: .weight, startValue: 80, targetValue: 80)
        #expect(goal.direction == .steady)
        #expect(goal.progress(currentValue: 80) == nil)
    }

    @Test func decreaseProgressAtStart() {
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        #expect(goal.progress(currentValue: 90) == 0.0)
    }

    @Test func decreaseProgressHalfway() {
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        #expect(goal.progress(currentValue: 85) == 0.5)
    }

    @Test func decreaseProgressComplete() {
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        #expect(goal.progress(currentValue: 80) == 1.0)
        #expect(goal.isComplete(currentValue: 80))
    }

    @Test func decreaseOvershoot() {
        // User went past their goal — progress > 1.0 is allowed.
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        let p = goal.progress(currentValue: 78)
        #expect(p != nil)
        #expect((p ?? 0) > 1.0)
        #expect(goal.isComplete(currentValue: 78))
    }

    @Test func increaseProgressHalfway() {
        let goal = BodyMetricGoal(metric: .bicepLeft, startValue: 35, targetValue: 40)
        #expect(goal.progress(currentValue: 37.5) == 0.5)
    }

    @Test func increaseOvershoot() {
        let goal = BodyMetricGoal(metric: .bicepLeft, startValue: 35, targetValue: 40)
        let p = goal.progress(currentValue: 42)
        #expect((p ?? 0) > 1.0)
        #expect(goal.isComplete(currentValue: 42))
    }

    @Test func regressionBelowStart() {
        // User went backward (e.g. weight went up when they wanted it to go down).
        // Progress goes negative; display layer clamps to 0.
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        let p = goal.progress(currentValue: 92)
        #expect(p != nil)
        #expect((p ?? 0) < 0)
        #expect(goal.progressFractionForDisplay(currentValue: 92) == 0)
        #expect(!goal.isComplete(currentValue: 92))
    }

    @Test func displayFractionClampedAbove() {
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        #expect(goal.progressFractionForDisplay(currentValue: 75) == 1.0)
    }

    @Test func persistsInSwiftData() throws {
        let schema = Schema([Peptide.self, Vial.self, DoseEntry.self, BodyMeasurement.self, BodyMetricGoal.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)
        let goal = BodyMetricGoal(metric: .weight, startValue: 90, targetValue: 80)
        ctx.insert(goal)
        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<BodyMetricGoal>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.metric == .weight)
    }
}
