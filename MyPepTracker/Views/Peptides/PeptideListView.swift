import SwiftUI
import SwiftData

struct PeptideListView: View {
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
    @State private var showingAddPeptide = false

    private var activePeptides: [Peptide] { allPeptides.filter(\.isActive) }
    private var archivedPeptides: [Peptide] { allPeptides.filter { !$0.isActive } }

    var body: some View {
        NavigationStack {
            List {
                if !activePeptides.isEmpty {
                    Section("Active") {
                        ForEach(activePeptides) { peptide in
                            NavigationLink(value: peptide) {
                                PeptideRowView(peptide: peptide)
                            }
                        }
                    }
                }

                if !archivedPeptides.isEmpty {
                    Section("Archived") {
                        ForEach(archivedPeptides) { peptide in
                            NavigationLink(value: peptide) {
                                PeptideRowView(peptide: peptide)
                            }
                        }
                    }
                }

                if allPeptides.isEmpty {
                    ContentUnavailableView(
                        "No Peptides Yet",
                        systemImage: "cube.box.fill",
                        description: Text("Tap + to add your first peptide.")
                    )
                }
            }
            .navigationTitle("Peptides")
            .navigationDestination(for: Peptide.self) { peptide in
                PeptideDetailView(peptide: peptide)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddPeptide = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPeptide) {
                AddPeptideView()
            }
        }
    }
}

struct PeptideRowView: View {
    let peptide: Peptide

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(peptide.name)
                .font(.body.weight(.medium))
            HStack(spacing: 8) {
                Text("\(Int(peptide.defaultDoseMcg))mcg")
                Text("•")
                Text(peptide.scheduleType.displayName)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 2)
    }
}
