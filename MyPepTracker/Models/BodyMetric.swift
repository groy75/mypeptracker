import Foundation
import SwiftUI

enum BodyMetric: String, Codable, CaseIterable, Hashable {
    case weight
    case bodyFatPercent
    case waist
    case neck
    case chest
    case backWidth
    case bicepLeft
    case bicepRight
    case thighLeft
    case thighRight

    enum Unit {
        case kilograms
        case centimeters
        case percent
    }

    var unit: Unit {
        switch self {
        case .weight: return .kilograms
        case .bodyFatPercent: return .percent
        case .waist, .neck, .chest, .backWidth,
             .bicepLeft, .bicepRight, .thighLeft, .thighRight:
            return .centimeters
        }
    }

    var displayName: String {
        switch self {
        case .weight:         return "Weight"
        case .bodyFatPercent: return "Body fat"
        case .waist:          return "Waist"
        case .neck:           return "Neck"
        case .chest:          return "Chest"
        case .backWidth:      return "Back width"
        case .bicepLeft:      return "Bicep (L)"
        case .bicepRight:     return "Bicep (R)"
        case .thighLeft:      return "Thigh (L)"
        case .thighRight:     return "Thigh (R)"
        }
    }

    var symbol: String {
        switch self {
        case .weight:         return "scalemass"
        case .bodyFatPercent: return "percent"
        case .waist:          return "figure"
        case .neck:           return "figure.arms.open"
        case .chest:          return "figure.core.training"
        case .backWidth:      return "figure.walk"
        case .bicepLeft, .bicepRight: return "figure.strengthtraining.traditional"
        case .thighLeft, .thighRight: return "figure.step.training"
        }
    }

    // Position on the silhouette used by BodyMapView (200x340 canvas).
    // Phase 3 reads this; phase 1 doesn't render the silhouette overlay yet.
    var bodyPosition: CGPoint? {
        switch self {
        case .weight, .bodyFatPercent:
            return nil
        case .waist:     return CGPoint(x: 100, y: 120)
        case .neck:      return CGPoint(x: 100, y: 50)
        case .chest:     return CGPoint(x: 100, y: 85)
        case .backWidth: return CGPoint(x: 100, y: 70)
        case .bicepLeft:  return CGPoint(x: 58,  y: 95)
        case .bicepRight: return CGPoint(x: 142, y: 95)
        case .thighLeft:  return CGPoint(x: 88,  y: 220)
        case .thighRight: return CGPoint(x: 112, y: 220)
        }
    }
}

// MARK: - Display

extension BodyMetric.Unit {
    /// Storage unit label (what the SI value represents).
    var storageSuffix: String {
        switch self {
        case .kilograms:   return "kg"
        case .centimeters: return "cm"
        case .percent:     return "%"
        }
    }

    /// Imperial counterpart label.
    var imperialSuffix: String {
        switch self {
        case .kilograms:   return "lb"
        case .centimeters: return "in"
        case .percent:     return "%"
        }
    }
}

/// Per-metric unit preference. Stored in UserDefaults as `unit_<metric.rawValue>`
/// — values `"metric"` or `"imperial"`. Falls back to the user's Settings
/// `preferImperial` toggle (the old global default) when unset, which in turn
/// falls back to the device locale's measurement system on first launch.
enum BodyMetricUnitPreference {
    private static func storageKey(for metric: BodyMetric) -> String { "unit_\(metric.rawValue)" }

    /// True if the user wants imperial for this metric.
    static func preferImperial(for metric: BodyMetric) -> Bool {
        let defaults = UserDefaults.standard
        if let stored = defaults.string(forKey: storageKey(for: metric)) {
            return stored == "imperial"
        }
        // Legacy global fallback if the user set one before we introduced
        // per-metric preferences.
        if defaults.object(forKey: "preferImperial") != nil {
            return defaults.bool(forKey: "preferImperial")
        }
        // Final fallback: device locale. US → imperial; everywhere else → metric.
        return Locale.current.measurementSystem == .us
    }

    /// Persist the user's choice for this metric.
    static func setPreferImperial(_ imperial: Bool, for metric: BodyMetric) {
        UserDefaults.standard.set(imperial ? "imperial" : "metric", forKey: storageKey(for: metric))
    }
}

enum BodyMetricFormat {
    /// Convert stored SI value → user's preferred display value.
    /// `imperial` toggles to lb/in; percent is unchanged.
    static func display(_ siValue: Double, unit: BodyMetric.Unit, imperial: Bool) -> Double {
        guard imperial else { return siValue }
        switch unit {
        case .kilograms:   return siValue * 2.2046226218
        case .centimeters: return siValue / 2.54
        case .percent:     return siValue
        }
    }

    /// Convert user's input → SI for storage.
    static func storage(_ inputValue: Double, unit: BodyMetric.Unit, imperial: Bool) -> Double {
        guard imperial else { return inputValue }
        switch unit {
        case .kilograms:   return inputValue / 2.2046226218
        case .centimeters: return inputValue * 2.54
        case .percent:     return inputValue
        }
    }

    static func formatted(_ siValue: Double, unit: BodyMetric.Unit, imperial: Bool) -> String {
        let display = display(siValue, unit: unit, imperial: imperial)
        let suffix = imperial ? unit.imperialSuffix : unit.storageSuffix
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let num = formatter.string(from: NSNumber(value: display)) ?? "\(display)"
        return "\(num) \(suffix)"
    }
}
