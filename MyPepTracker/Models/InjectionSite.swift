import Foundation

enum InjectionSite: String, Codable, CaseIterable {
    case abdomen
    case thighLeft
    case thighRight
    case deltoidLeft
    case deltoidRight
    case gluteLeft
    case gluteRight
    case other

    var displayName: String {
        switch self {
        case .abdomen: "Abdomen"
        case .thighLeft: "Left Thigh"
        case .thighRight: "Right Thigh"
        case .deltoidLeft: "Left Deltoid"
        case .deltoidRight: "Right Deltoid"
        case .gluteLeft: "Left Glute"
        case .gluteRight: "Right Glute"
        case .other: "Other"
        }
    }
}
