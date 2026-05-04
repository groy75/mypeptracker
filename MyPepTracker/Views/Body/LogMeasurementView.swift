import SwiftUI
import SwiftData

struct LogMeasurementView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    /// A LogMeasurementView is always scoped to one metric — users enter it
    /// from the metric's detail view. The no-picker design mirrors how the
    /// Log Dose flow works for peptides: pick the subject first, log second.
    let metric: BodyMetric
    let preferImperial: Bool

    @State private var inputValue: String = ""
    @State private var timestamp: Date = .now
    @State private var notes: String = ""

    init(preselectedMetric: BodyMetric) {
        self.metric = preselectedMetric
        self.preferImperial = BodyMetricUnitPreference.preferImperial(for: preselectedMetric)
    }

    private var unitSuffix: String {
        preferImperial ? metric.unit.imperialSuffix : metric.unit.storageSuffix
    }

    private var canSave: Bool {
        Double(inputValue) != nil && (Double(inputValue) ?? 0) > 0
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: metric.symbol)
                        .font(.title2)
                        .foregroundStyle(AppTheme.primary)
                    Text("Recording your current \(metric.displayName.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Section(metric.displayName) {
                HStack {
                    TextField("Value", text: $inputValue)
                        .keyboardType(.decimalPad)
                    Text(unitSuffix)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                DatePicker("When", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Notes") {
                TextField("Optional", text: $notes, axis: .vertical)
                    .lineLimit(1...4)
            }
        }
        .navigationTitle("Log \(metric.displayName.lowercased())")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
    }

    @AppStorage("healthKitEnabled") private var healthKitEnabled = false

    private func save() {
        guard let input = Double(inputValue) else { return }
        let siValue = BodyMetricFormat.storage(input, unit: metric.unit, imperial: preferImperial)
        let entry = BodyMeasurement(
            metric: metric,
            value: siValue,
            timestamp: timestamp,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        context.insert(entry)
        do {
            try context.save()
        } catch {
            appState.showToast("Save failed — please try again.")
            return
        }

        if healthKitEnabled {
            Task {
                await HealthKitService.shared.write(metric: metric, value: siValue, date: timestamp)
            }
        }

        appState.showToast("\(metric.displayName): \(BodyMetricFormat.formatted(siValue, unit: metric.unit, imperial: preferImperial))")
        dismiss()
    }
}
