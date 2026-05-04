import SwiftUI
import SwiftData
import Charts

/// Detail view for a single body metric: chart, goal, history.
///
/// **Architecture note:** This view does four things:
/// 1. Chart rendering (Swift Charts) with 7-day rolling mean overlay
/// 2. Goal card with progress bar and narrative
/// 3. History list with delete support
/// 4. Per-metric unit toggle (kg/lb or cm/in)
///
/// **Performance note:** The `rollingMean` property uses a sliding window
/// algorithm (O(n)) instead of the original O(n²) filter-per-entry approach.
/// The `dateString` method uses a static cached DateFormatter.
///
/// **SwiftData quirk:** We fetch ALL BodyMeasurement entries and filter
/// in-memory because `#Predicate` traversing enum rawValue on @Model
/// enums crashes at query time on some builds.
struct MetricDetailView: View {
    @Environment(\.modelContext) private var context
    let metric: BodyMetric

    // SwiftData's #Predicate cannot safely traverse enum rawValue paths on
    // @Model-stored enums (it crashes at query time on some builds). Fetch
    // everything and filter in-memory — per-metric entry counts are tiny.
    @Query(sort: \BodyMeasurement.timestamp, order: .forward) private var allEntries: [BodyMeasurement]
    @Query private var allGoals: [BodyMetricGoal]

    // Per-metric unit preference. Starts from the stored value; writes back
    // to UserDefaults via the BodyMetricUnitPreference helper when toggled.
    @State private var preferImperial: Bool

    @State private var showingLogSheet = false
    @State private var showingGoalSheet = false

    init(metric: BodyMetric) {
        self.metric = metric
        _preferImperial = State(initialValue: BodyMetricUnitPreference.preferImperial(for: metric))
    }

    private var entries: [BodyMeasurement] {
        allEntries.filter { $0.metric == metric }
    }

    private var goal: BodyMetricGoal? {
        allGoals.first { $0.metric == metric }
    }

    private var latest: BodyMeasurement? { entries.last }

    /// Simple 7-day rolling mean for the chart overlay — smooths daily noise (esp. weight).
    /// Uses a sliding window for O(n) performance instead of O(n²).
    private var rollingMean: [(date: Date, value: Double)] {
        guard entries.count >= 2 else { return [] }
        let window: TimeInterval = 7 * 24 * 3600
        var result: [(date: Date, value: Double)] = []
        var windowSum: Double = 0
        var windowStart = 0

        for (idx, entry) in entries.enumerated() {
            let cutoff = entry.timestamp.addingTimeInterval(-window)
            // Advance window start to first entry within the window
            while windowStart < idx && entries[windowStart].timestamp < cutoff {
                windowSum -= entries[windowStart].value
                windowStart += 1
            }
            windowSum += entry.value
            let count = idx - windowStart + 1
            result.append((entry.timestamp, windowSum / Double(count)))
        }
        return result
    }

    private var unitSuffix: String {
        preferImperial ? metric.unit.imperialSuffix : metric.unit.storageSuffix
    }

    /// Unit chip toggles kg↔lb or cm↔in for this metric only. Percent is
    /// unitless — we hide the chip for body fat.
    private var supportsUnitToggle: Bool { metric.unit != .percent }

    private func toggleUnit() {
        preferImperial.toggle()
        BodyMetricUnitPreference.setPreferImperial(preferImperial, for: metric)
    }

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                chart
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Goal") {
                goalCard
            }

            Section("History (\(entries.count))") {
                if entries.isEmpty {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Label("Record your current \(metric.displayName.lowercased())", systemImage: "plus.circle.fill")
                    }
                } else {
                    ForEach(entries.reversed()) { entry in
                        historyRow(entry)
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle(metric.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingLogSheet = true
                } label: {
                    Label("Log \(metric.displayName.lowercased())", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            NavigationStack {
                LogMeasurementView(preselectedMetric: metric)
            }
        }
        .sheet(isPresented: $showingGoalSheet) {
            NavigationStack {
                SetGoalSheet(metric: metric, existing: goal, currentValue: latest?.value)
            }
        }
    }

    @ViewBuilder
    private var goalCard: some View {
        if let g = goal, let current = latest?.value {
            let progress = g.progressFractionForDisplay(currentValue: current)
            let narrative = g.narrative(currentValue: current, preferImperial: preferImperial)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(narrative)
                            .font(.body.monospacedDigit())
                        Text("Target: \(BodyMetricFormat.formatted(g.targetValue, unit: metric.unit, imperial: preferImperial))\(g.targetDate.map { " by \(dateString($0))" } ?? "")")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button { showingGoalSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                }
                ProgressView(value: progress)
                    .tint(g.isComplete(currentValue: current) ? AppTheme.success : AppTheme.primary)
            }
            .padding(.vertical, 4)
        } else {
            Button {
                showingGoalSheet = true
            } label: {
                Label("Set a goal", systemImage: "target")
            }
        }
    }



    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt
    }()

    private func dateString(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Image(systemName: metric.symbol)
                .font(.largeTitle)
                .foregroundStyle(AppTheme.primary)
            VStack(alignment: .leading, spacing: 4) {
                if let latest {
                    Text(BodyMetricFormat.formatted(latest.value, unit: metric.unit, imperial: preferImperial))
                        .font(.title.monospacedDigit())
                    Text("Last logged \(latest.timestamp, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("No measurements yet")
                        .font(.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            if supportsUnitToggle {
                // Small segmented control to flip between metric and imperial.
                Picker("Unit", selection: Binding(
                    get: { preferImperial },
                    set: { newValue in
                        preferImperial = newValue
                        BodyMetricUnitPreference.setPreferImperial(newValue, for: metric)
                    }
                )) {
                    Text(metric.unit.storageSuffix).tag(false)
                    Text(metric.unit.imperialSuffix).tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .accessibilityLabel("Unit for \(metric.displayName)")
            }
        }
        .padding()
    }

    @ViewBuilder
    private var chart: some View {
        if entries.count >= 2 {
            Chart {
                ForEach(entries) { entry in
                    let displayed = BodyMetricFormat.display(entry.value, unit: metric.unit, imperial: preferImperial)
                    LineMark(
                        x: .value("Date", entry.timestamp),
                        y: .value(metric.displayName, displayed)
                    )
                    .foregroundStyle(AppTheme.primary)
                    PointMark(
                        x: .value("Date", entry.timestamp),
                        y: .value(metric.displayName, displayed)
                    )
                    .foregroundStyle(AppTheme.primary)
                    .symbolSize(30)
                }

                // Horizontal goal line, if a goal is set for this metric.
                if let g = goal {
                    let displayedGoal = BodyMetricFormat.display(g.targetValue, unit: metric.unit, imperial: preferImperial)
                    RuleMark(y: .value("Goal", displayedGoal))
                        .foregroundStyle(AppTheme.warning.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.warning)
                                .padding(.horizontal, 4)
                        }
                }

                // Rolling mean — helps weight especially, which fluctuates daily.
                if metric == .weight, rollingMean.count >= 2 {
                    ForEach(rollingMean, id: \.date) { point in
                        let displayed = BodyMetricFormat.display(point.value, unit: metric.unit, imperial: preferImperial)
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("7-day mean", displayed)
                        )
                        .foregroundStyle(AppTheme.success.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    }
                }
            }
            .frame(height: 220)
            .padding()
        } else if entries.count == 1 {
            Text("Log one more entry to see a chart.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .padding()
        }
    }

    @ViewBuilder
    private func historyRow(_ entry: BodyMeasurement) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.timestamp, style: .date)
                    .font(.body)
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text(BodyMetricFormat.formatted(entry.value, unit: metric.unit, imperial: preferImperial))
                .font(.body.monospacedDigit())
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func delete(at offsets: IndexSet) {
        // offsets index into the reversed array shown in the list.
        let reversed = Array(entries.reversed())
        for idx in offsets {
            context.delete(reversed[idx])
        }
        try? context.save()
    }
}
