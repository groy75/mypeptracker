import SwiftUI
import SwiftData

struct SetGoalSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @AppStorage("preferImperial") private var preferImperial = false

    let metric: BodyMetric
    /// If non-nil, user is editing this existing goal instead of creating one.
    let existing: BodyMetricGoal?
    /// Latest measurement for sensible defaults on start value.
    let currentValue: Double?

    @State private var startInput: String
    @State private var targetInput: String
    @State private var startDate: Date
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date

    init(metric: BodyMetric, existing: BodyMetricGoal? = nil, currentValue: Double? = nil) {
        self.metric = metric
        self.existing = existing
        self.currentValue = currentValue

        // Wrap SwiftUI @State init via an isolated helper.
        let imperial = UserDefaults.standard.bool(forKey: "preferImperial")
        let fmt: (Double?) -> String = { v in
            guard let v else { return "" }
            let display = BodyMetricFormat.display(v, unit: metric.unit, imperial: imperial)
            return String(format: "%.1f", display)
        }

        if let existing {
            _startInput = State(initialValue: fmt(existing.startValue))
            _targetInput = State(initialValue: fmt(existing.targetValue))
            _startDate = State(initialValue: existing.startDate)
            _hasTargetDate = State(initialValue: existing.targetDate != nil)
            _targetDate = State(initialValue: existing.targetDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date())
        } else {
            _startInput = State(initialValue: fmt(currentValue))
            _targetInput = State(initialValue: "")
            _startDate = State(initialValue: Date())
            _hasTargetDate = State(initialValue: false)
            _targetDate = State(initialValue: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date())
        }
    }

    private var unitSuffix: String {
        preferImperial ? metric.unit.imperialSuffix : metric.unit.storageSuffix
    }

    private var parsedStart: Double? { Double(startInput) }
    private var parsedTarget: Double? { Double(targetInput) }

    private var canSave: Bool {
        guard let s = parsedStart, let t = parsedTarget else { return false }
        return s > 0 && t > 0 && s != t
    }

    private var directionHint: String? {
        guard let s = parsedStart, let t = parsedTarget, s != t else { return nil }
        let delta = t - s
        let sign = delta > 0 ? "increase" : "decrease"
        let magnitude = String(format: "%.1f", abs(delta))
        return "Will \(sign) by \(magnitude) \(unitSuffix)"
    }

    var body: some View {
        Form {
            Section(metric.displayName) {
                LabeledContent("Unit", value: unitSuffix)
            }

            Section("Start") {
                HStack {
                    TextField("Value", text: $startInput)
                        .keyboardType(.decimalPad)
                    Text(unitSuffix).foregroundStyle(AppTheme.textSecondary)
                }
                DatePicker("Date", selection: $startDate, displayedComponents: .date)
            }

            Section("Target") {
                HStack {
                    TextField("Value", text: $targetInput)
                        .keyboardType(.decimalPad)
                    Text(unitSuffix).foregroundStyle(AppTheme.textSecondary)
                }
                Toggle("Set target date", isOn: $hasTargetDate)
                if hasTargetDate {
                    DatePicker("By", selection: $targetDate, in: Date()..., displayedComponents: .date)
                }
                if let hint = directionHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if existing != nil {
                Section {
                    Button(role: .destructive) { delete() } label: {
                        Label("Delete goal", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(existing == nil ? "Set goal" : "Edit goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!canSave)
            }
        }
    }

    private func save() {
        guard let s = parsedStart, let t = parsedTarget else { return }
        let siStart = BodyMetricFormat.storage(s, unit: metric.unit, imperial: preferImperial)
        let siTarget = BodyMetricFormat.storage(t, unit: metric.unit, imperial: preferImperial)
        let resolvedTargetDate = hasTargetDate ? targetDate : nil

        // Upsert semantics: one active goal per metric. If an existing goal
        // exists for this metric (or we're editing one), mutate in place;
        // otherwise insert a new one.
        if let existing {
            existing.startValue = siStart
            existing.startDate = startDate
            existing.targetValue = siTarget
            existing.targetDate = resolvedTargetDate
        } else {
            // Delete any stale goal for this metric before inserting.
            let rawMetric = metric.rawValue
            let predicate = #Predicate<BodyMetricGoal> { $0.metric.rawValue == rawMetric }
            if let stale = try? context.fetch(FetchDescriptor(predicate: predicate)) {
                for g in stale { context.delete(g) }
            }
            let goal = BodyMetricGoal(
                metric: metric,
                startValue: siStart,
                targetValue: siTarget,
                startDate: startDate,
                targetDate: resolvedTargetDate
            )
            context.insert(goal)
        }
        try? context.save()
        appState.showToast("\(metric.displayName) goal saved")
        dismiss()
    }

    private func delete() {
        guard let existing else { return }
        context.delete(existing)
        try? context.save()
        appState.showToast("\(metric.displayName) goal removed")
        dismiss()
    }
}
