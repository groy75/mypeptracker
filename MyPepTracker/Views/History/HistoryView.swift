import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DoseEntry.timestamp, order: .reverse) private var allDoses: [DoseEntry]
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]

    @State private var selectedPeptide: Peptide?
    @State private var showBodyMap = false
    @State private var dosePendingDeletion: DoseEntry?

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
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        dosePendingDeletion = dose
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .confirmationDialog(
                "Delete this dose?",
                isPresented: Binding(
                    get: { dosePendingDeletion != nil },
                    set: { if !$0 { dosePendingDeletion = nil } }
                ),
                titleVisibility: .visible,
                presenting: dosePendingDeletion
            ) { dose in
                Button("Delete Dose", role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    deleteDose(dose)
                    dosePendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { dosePendingDeletion = nil }
            } message: { dose in
                let peptideName = dose.peptide?.name ?? "peptide"
                Text("Removes \(safeInt(dose.doseMcg))mcg of \(peptideName). Any vial volume used by this dose will be returned.")
            }
        }
    }

    private func deleteDose(_ dose: DoseEntry) {
        if let vial = dose.vial {
            vial.totalVolumeUsedML = max(0, vial.totalVolumeUsedML - dose.unitsInjectedML)
        }
        modelContext.delete(dose)
    }
}
