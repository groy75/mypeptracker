import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), nextDosePeptide: "BPC-157", nextDoseInMinutes: 120, activeVials: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()

        // Update every 15 minutes for the next 4 hours
        for offset in stride(from: 0, through: 240, by: 15) {
            let entryDate = currentDate.addingTimeInterval(TimeInterval(offset * 60))
            var entry = loadEntry()
            entry.date = entryDate
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func loadEntry() -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.greg.roy.MyPepTracker")
        let peptide = defaults?.string(forKey: "widget_nextDosePeptide") ?? "No doses scheduled"
        let minutes = defaults?.integer(forKey: "widget_nextDoseMinutes") ?? 0
        let vials = defaults?.integer(forKey: "widget_activeVials") ?? 0
        return SimpleEntry(date: Date(), nextDosePeptide: peptide, nextDoseInMinutes: minutes, activeVials: vials)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    let nextDosePeptide: String
    let nextDoseInMinutes: Int
    let activeVials: Int
}

struct MyPepTrackerWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(entry.nextDosePeptide, systemImage: "pill.fill")
        case .accessoryCircular:
            VStack {
                Image(systemName: "pill.fill")
                    .font(.title)
                Text(entry.nextDosePeptide)
                    .font(.caption)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(entry.nextDosePeptide)
                    .font(.headline)
                if entry.nextDoseInMinutes > 0 {
                    Text("in \(entry.nextDoseInMinutes / 60)h \(entry.nextDoseInMinutes % 60)m")
                        .font(.caption)
                }
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "pill.fill")
                        .foregroundStyle(.accent)
                    Text(entry.nextDosePeptide)
                        .font(.headline)
                }
                if entry.nextDoseInMinutes > 0 {
                    Text("Next dose in \(entry.nextDoseInMinutes / 60)h \(entry.nextDoseInMinutes % 60)m")
                        .font(.subheadline)
                }
                Text("\(entry.activeVials) active vial(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct MyPepTrackerWidget: Widget {
    let kind: String = "MyPepTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MyPepTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MyPepTracker")
        .description("Shows your next scheduled dose and active vials.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    MyPepTrackerWidget()
} timeline: {
    SimpleEntry(date: .now, nextDosePeptide: "BPC-157", nextDoseInMinutes: 120, activeVials: 2)
    SimpleEntry(date: .now.addingTimeInterval(3600), nextDosePeptide: "BPC-157", nextDoseInMinutes: 60, activeVials: 2)
}
