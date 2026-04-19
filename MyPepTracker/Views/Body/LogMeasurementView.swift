import SwiftUI
import SwiftData

struct LogMeasurementView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @AppStorage("preferImperial") private var preferImperial = false

    let preselectedMetric: BodyMetric?

    @State private var metric: BodyMetric
    @State private var inputValue: String = ""
    @State private var timestamp: Date = .now
    @State private var notes: String = ""

    init(preselectedMetric: BodyMetric? = nil) {
        self.preselectedMetric = preselectedMetric
        _metric = State(initialValue: preselectedMetric ?? .weight)
    }

    private var unitSuffix: String {
        preferImperial ? metric.unit.imperialSuffix : metric.unit.storageSuffix
    }

    private var canSave: Bool {
        Double(inputValue) != nil && (Double(inputValue) ?? 0) > 0
    }

    var body: some View {
        Form {
            Section("Metric") {
                if preselectedMetric != nil {
                    LabeledContent("Metric", value: metric.displayName)
                } else {
                    Picker("Metric", selection: $metric) {
                        ForEach(BodyMetric.allCases, id: \.self) { m in
                            Label(m.displayName, systemImage: m.symbol).tag(m)
                        }
                    }
                }
            }

            Section("Value") {
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
        .navigationTitle("Log measurement")
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
        try? context.save()
        appState.showToast("Logged \(BodyMetricFormat.formatted(siValue, unit: metric.unit, imperial: preferImperial)) (\(metric.displayName))")
        dismiss()
    }
}
