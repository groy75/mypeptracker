import SwiftUI
import SwiftData
import Charts

struct MetricDetailView: View {
    @Environment(\.modelContext) private var context
    let metric: BodyMetric

    // SwiftData's #Predicate cannot safely traverse enum rawValue paths on
    // @Model-stored enums (it crashes at query time on some builds). Fetch
    // everything and filter in-memory — per-metric entry counts are tiny.
    @Query(sort: \BodyMeasurement.timestamp, order: .forward) private var allEntries: [BodyMeasurement]
    @Query private var allGoals: [BodyMetricGoal]
    @AppStorage("preferImperial") private var preferImperial = false

    @State private var showingLogSheet = false
    @State private var showingGoalSheet = false

    init(metric: BodyMetric) {
        self.metric = metric
    }

    private var entries: [BodyMeasurement] {
        allEntries.filter { $0.metric == metric }
    }

    private var goal: BodyMetricGoal? {
        allGoals.first { $0.metric == metric }
    }

    private var latest: BodyMeasurement? { entries.last }

    /// Simple 7-day rolling mean for the chart overlay — smooths daily noise (esp. weight).
    private var rollingMean: [(date: Date, value: Double)] {
        guard entries.count >= 2 else { return [] }
        let window: TimeInterval = 7 * 24 * 3600
        return entries.map { entry in
            let cutoff = entry.timestamp.addingTimeInterval(-window)
            let windowEntries = entries.filter { $0.timestamp >= cutoff && $0.timestamp <= entry.timestamp }
            let mean = windowEntries.map(\.value).reduce(0, +) / Double(windowEntries.count)
            return (entry.timestamp, mean)
        }
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
                    Text("No entries yet — tap + to log one.")
                        .foregroundStyle(AppTheme.textSecondary)
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
                    Label("Log", systemImage: "plus")
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
            let narrative = goalNarrative(goal: g, current: current)
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

    private func goalNarrative(goal g: BodyMetricGoal, current: Double) -> String {
        let imperial = preferImperial
        let unit = metric.unit
        let suffix = imperial ? unit.imperialSuffix : unit.storageSuffix
        switch g.direction {
        case .increase:
            let gained = BodyMetricFormat.display(max(current - g.startValue, 0), unit: unit, imperial: imperial)
            let needed = BodyMetricFormat.display(g.targetValue - g.startValue, unit: unit, imperial: imperial)
            return String(format: "%.1f of %.1f %@ gained", gained, needed, suffix)
        case .decrease:
            let lost = BodyMetricFormat.display(max(g.startValue - current, 0), unit: unit, imperial: imperial)
            let needed = BodyMetricFormat.display(g.startValue - g.targetValue, unit: unit, imperial: imperial)
            return String(format: "%.1f of %.1f %@ lost", lost, needed, suffix)
        case .steady:
            return "Hold steady at \(BodyMetricFormat.formatted(g.targetValue, unit: unit, imperial: imperial))"
        }
    }

    private func dateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Image(systemName: metric.symbol)
                .font(.largeTitle)
                .foregroundStyle(AppTheme.primary)
            VStack(alignment: .leading) {
                if let latest {
                    Text(BodyMetricFormat.formatted(latest.value, unit: metric.unit, imperial: preferImperial))
                        .font(.title.monospacedDigit())
                    Text("Last logged \(latest.timestamp, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("—")
                        .font(.title.monospacedDigit())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
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
        } else {
            Text("Log at least two entries to see a chart.")
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
