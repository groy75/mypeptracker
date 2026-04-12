import Foundation
import SwiftData

@Model
final class Peptide {
    var name: String
    var defaultDoseMcg: Double
    var scheduleType: ScheduleType
    var frequency: DoseFrequency
    var scheduledTime: Date?
    var scheduleDays: [Int]?
    var notes: String?
    var isActive: Bool

    // Cycle tracking
    var cycleStartDate: Date?
    var cycleLengthWeeks: Int?
    var cycleNotes: String?

    @Relationship(deleteRule: .cascade, inverse: \Vial.peptide)
    var vials: [Vial] = []

    @Relationship(deleteRule: .cascade, inverse: \DoseEntry.peptide)
    var doseEntries: [DoseEntry] = []

    var activeVial: Vial? {
        vials.first { $0.isActive && !$0.isExpired }
    }

    var lastDose: DoseEntry? {
        doseEntries.sorted { $0.timestamp > $1.timestamp }.first
    }

    var cycleEndDate: Date? {
        guard let start = cycleStartDate, let weeks = cycleLengthWeeks else { return nil }
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: start)
    }

    var cycleProgress: Double? {
        guard let start = cycleStartDate, let end = cycleEndDate else { return nil }
        let total = end.timeIntervalSince(start)
        let elapsed = Date().timeIntervalSince(start)
        return min(max(elapsed / total, 0), 1.0)
    }

    var cycleDaysRemaining: Int? {
        guard let end = cycleEndDate else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0)
    }

    init(
        name: String,
        defaultDoseMcg: Double,
        scheduleType: ScheduleType,
        frequency: DoseFrequency,
        scheduledTime: Date? = nil,
        scheduleDays: [Int]? = nil,
        notes: String? = nil,
        isActive: Bool = true,
        cycleStartDate: Date? = nil,
        cycleLengthWeeks: Int? = nil,
        cycleNotes: String? = nil
    ) {
        self.name = name
        self.defaultDoseMcg = defaultDoseMcg
        self.scheduleType = scheduleType
        self.frequency = frequency
        self.scheduledTime = scheduledTime
        self.scheduleDays = scheduleDays
        self.notes = notes
        self.isActive = isActive
        self.cycleStartDate = cycleStartDate
        self.cycleLengthWeeks = cycleLengthWeeks
        self.cycleNotes = cycleNotes
    }
}
