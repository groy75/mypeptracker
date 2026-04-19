import SwiftUI
import SwiftData

struct BodyView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: \BodyMeasurement.timestamp, order: .reverse) private var allMeasurements: [BodyMeasurement]
    @Query private var allGoals: [BodyMetricGoal]
    @AppStorage("preferImperial") private var preferImperial = false

    @State private var showingLogSheet = false
    @State private var preselectedMetric: BodyMetric?

    // Latest entry per metric.
    private var latestByMetric: [BodyMetric: BodyMeasurement] {
        var out: [BodyMetric: BodyMeasurement] = [:]
        for entry in allMeasurements where out[entry.metric] == nil {
            out[entry.metric] = entry
        }
        return out
    }

    // 7-day delta per metric: latest minus most recent entry older than 7 days.
    private func sevenDayDelta(for metric: BodyMetric) -> Double? {
        let entries = allMeasurements.filter { $0.metric == metric }
        guard let latest = entries.first else { return nil }
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        let prior = entries.first { $0.timestamp < cutoff }
        guard let prior else { return nil }
        return latest.value - prior.value
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(BodyMetric.allCases, id: \.self) { metric in
                    NavigationLink {
                        MetricDetailView(metric: metric)
                    } label: {
                        row(for: metric)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            preselectedMetric = metric
                            showingLogSheet = true
                        } label: {
                            Label("Log", systemImage: "plus")
                        }
                        .tint(AppTheme.primary)
                    }
                }
            }
            .navigationTitle("Body")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        preselectedMetric = nil
                        showingLogSheet = true
                    } label: {
                        Label("Log measurement", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                NavigationStack {
                    LogMeasurementView(preselectedMetric: preselectedMetric)
                }
            }
        }
    }

    private func goal(for metric: BodyMetric) -> BodyMetricGoal? {
        allGoals.first { $0.metric == metric }
    }

    @ViewBuilder
    private func row(for metric: BodyMetric) -> some View {
        let latest = latestByMetric[metric]
        let delta = sevenDayDelta(for: metric)
        let goalForRow = goal(for: metric)

        VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 12) {
            Image(systemName: metric.symbol)
                .font(.title3)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.displayName)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                if let latest {
                    Text(latest.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("No entries")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let latest {
                    Text(BodyMetricFormat.formatted(latest.value, unit: metric.unit, imperial: preferImperial))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(AppTheme.textPrimary)
                } else {
                    Text("—")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                if let delta, abs(delta) > 0.0001 {
                    let displayDelta = BodyMetricFormat.display(delta, unit: metric.unit, imperial: preferImperial)
                    let suffix = preferImperial ? metric.unit.imperialSuffix : metric.unit.storageSuffix
                    let sign = delta > 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.1f", displayDelta)) \(suffix) / 7d")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(delta > 0 ? AppTheme.success : AppTheme.warning)
                }
            }
        }
        // Goal progress bar (only when a goal and at least one logged value exist).
        if let g = goalForRow, let current = latest?.value {
            let progress = g.progressFractionForDisplay(currentValue: current)
            ProgressView(value: progress)
                .tint(g.isComplete(currentValue: current) ? AppTheme.success : AppTheme.primary)
                .accessibilityLabel("\(metric.displayName) goal progress")
                .accessibilityValue(String(format: "%.0f percent", progress * 100))
        }
        }
        .padding(.vertical, 4)
    }
}
