import Foundation
import SwiftData

@Model
final class Peptide {
    var name: String
    var defaultDoseMcg: Double
    var scheduleType: ScheduleType
    var frequencyHours: Double
    var scheduledTime: Date?
    var scheduleDays: [Int]?
    var notes: String?
    var isActive: Bool

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

    init(
        name: String,
        defaultDoseMcg: Double,
        scheduleType: ScheduleType,
        frequencyHours: Double,
        scheduledTime: Date? = nil,
        scheduleDays: [Int]? = nil,
        notes: String? = nil,
        isActive: Bool = true
    ) {
        self.name = name
        self.defaultDoseMcg = defaultDoseMcg
        self.scheduleType = scheduleType
        self.frequencyHours = frequencyHours
        self.scheduledTime = scheduledTime
        self.scheduleDays = scheduleDays
        self.notes = notes
        self.isActive = isActive
    }
}
