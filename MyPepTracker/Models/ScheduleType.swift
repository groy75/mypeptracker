import Foundation

enum ScheduleType: String, Codable, CaseIterable {
    case fixedRecurring
    case afterDose

    var displayName: String {
        switch self {
        case .fixedRecurring: "Fixed Schedule"
        case .afterDose: "After Last Dose"
        }
    }
}
