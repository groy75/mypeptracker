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

    /// Position of this injection site on the AthleticSilhouette's
    /// 320x560 reference canvas. Front-facing approximation — glutes
    /// render as markers at the hip area since we only draw the front.
    /// `.other` sits just below the figure so it's visible without
    /// overlapping anatomy.
    var silhouettePosition: CGPoint {
        switch self {
        case .abdomen:      return CGPoint(x: 160, y: 225)
        case .thighLeft:    return CGPoint(x: 132, y: 400)
        case .thighRight:   return CGPoint(x: 188, y: 400)
        case .deltoidLeft:  return CGPoint(x: 90,  y: 140)
        case .deltoidRight: return CGPoint(x: 230, y: 140)
        case .gluteLeft:    return CGPoint(x: 130, y: 325)
        case .gluteRight:   return CGPoint(x: 190, y: 325)
        case .other:        return CGPoint(x: 160, y: 555)
        }
    }
}
