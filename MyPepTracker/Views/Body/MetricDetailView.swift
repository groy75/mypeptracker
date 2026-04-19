import SwiftUI
import SwiftData
import Charts

struct MetricDetailView: View {
    @Environment(\.modelContext) private var context
    let metric: BodyMetric

    @Query private var entries: [BodyMeasurement]
    @AppStorage("preferImperial") private var preferImperial = false

    @State private var showingLogSheet = false

    init(metric: BodyMetric) {
        self.metric = metric
        // Predicate on enum stored as rawValue-backed attribute.
        let raw = metric.rawValue
        _entries = Query(
            filter: #Predicate<BodyMeasurement> { $0.metric.rawValue == raw },
            sort: \.timestamp,
            order: .forward
        )
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
