import Foundation

enum DoseFrequency: String, Codable, CaseIterable {
    case twiceDaily
    case daily
    case everyOtherDay
    case threeTimesWeekly
    case twiceWeekly
    case weekly
    case biweekly
    case monthly

    var displayName: String {
        switch self {
        case .twiceDaily: "Twice Daily"
        case .daily: "Daily"
        case .everyOtherDay: "Every Other Day"
        case .threeTimesWeekly: "3× Weekly"
        case .twiceWeekly: "2× Weekly"
        case .weekly: "Weekly"
        case .biweekly: "Every 2 Weeks"
        case .monthly: "Monthly"
        }
    }

    var hours: Double {
        switch self {
        case .twiceDaily: 12
        case .daily: 24
        case .everyOtherDay: 48
        case .threeTimesWeekly: 56
        case .twiceWeekly: 84
        case .weekly: 168
        case .biweekly: 336
        case .monthly: 720
        }
    }
}
