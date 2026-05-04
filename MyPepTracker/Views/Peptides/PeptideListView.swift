import SwiftUI
import SwiftData
import UIKit

struct PeptideListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
    @State private var showingAddPeptide = false
    @State private var peptidePendingDeletion: Peptide?

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    peptidePendingDeletion = peptide
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    peptidePendingDeletion = peptide
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
                    .accessibilityLabel("Add peptide")
                }
            }
            .sheet(isPresented: $showingAddPeptide) {
                AddPeptideView()
            }
            .confirmationDialog(
                peptidePendingDeletion.map { "Delete \($0.name)?" } ?? "Delete peptide?",
                isPresented: Binding(
                    get: { peptidePendingDeletion != nil },
                    set: { if !$0 { peptidePendingDeletion = nil } }
                ),
                titleVisibility: .visible,
                presenting: peptidePendingDeletion
            ) { peptide in
                Button("Delete Peptide & History", role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    NotificationManager.shared.cancelAll(for: peptide)
                    modelContext.delete(peptide)
                    peptidePendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    peptidePendingDeletion = nil
                }
            } message: { _ in
                Text("This permanently deletes the peptide, all vials, and all dose history. This cannot be undone.")
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
                Text("\(safeInt(peptide.defaultDoseMcg))mcg")
                Text("•")
                Text(peptide.scheduleType.displayName)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 2)
    }
}
