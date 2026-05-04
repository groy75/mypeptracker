import HealthKit
import Foundation

/// Bridges body measurements to Apple Health. Users must grant write permission
/// for each metric type before data flows.
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    private init() {}

    /// Returns true if HealthKit is available on this device.
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Requests write permission for supported body metrics.
    /// Call this from Settings or before the first log.
    func requestPermission() async -> Bool {
        guard isAvailable else { return false }

        let types: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
        ]

        do {
            try await store.requestAuthorization(toShare: types, read: [])
            return true
        } catch {
            return false
        }
    }

    /// Writes a body measurement to HealthKit if the metric is supported.
    func write(metric: BodyMetric, value: Double, date: Date) async {
        guard isAvailable else { return }

        let quantityType: HKQuantityType?
        let unit: HKUnit?

        switch metric {
        case .weight:
            quantityType = HKQuantityType.quantityType(forIdentifier: .bodyMass)
            unit = .gramUnit(with: .kilo)
        case .bodyFatPercent:
            quantityType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
            unit = .percent()
        default:
            quantityType = nil
            unit = nil
        }

        guard let quantityType, let unit else { return }

        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: date,
            end: date
        )

        do {
            try await store.save(sample)
        } catch {
            // Silently fail — HealthKit is best-effort. Don't block the UX.
        }
    }
}
