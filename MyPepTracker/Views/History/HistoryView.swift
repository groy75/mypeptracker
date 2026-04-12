import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DoseEntry.timestamp, order: .reverse) private var allDoses: [DoseEntry]
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]

    @State private var selectedPeptide: Peptide?
    @State private var showBodyMap = false

    private var filteredDoses: [DoseEntry] {
        if let selected = selectedPeptide {
            return allDoses.filter { $0.peptide?.persistentModelID == selected.persistentModelID }
        }
        return Array(allDoses)
    }

    private var last30DaysDoses: [DoseEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return allDoses.filter { $0.timestamp > cutoff }
    }

    var body: some View {
        NavigationStack {
            List {
                if allPeptides.count > 1 {
                    Section {
                        Picker("Filter", selection: $selectedPeptide) {
                            Text("All Peptides").tag(nil as Peptide?)
                            ForEach(allPeptides) { peptide in
                                Text(peptide.name).tag(peptide as Peptide?)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if !allDoses.isEmpty {
                    Section {
                        Button {
                            showBodyMap.toggle()
                        } label: {
                            Label(
                                showBodyMap ? "Hide Body Map" : "Show Injection Sites",
                                systemImage: "figure.stand"
                            )
                        }

                        if showBodyMap {
                            BodyMapView(recentDoses: last30DaysDoses)
                        }
                    }
                }

                if filteredDoses.isEmpty {
                    ContentUnavailableView(
                        "No Dose History",
                        systemImage: "list.clipboard.fill",
                        description: Text("Logged doses will appear here.")
                    )
                } else {
                    Section("Doses") {
                        ForEach(filteredDoses) { dose in
                            DoseEntryRow(entry: dose)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}
