import SwiftUI
import SwiftData
import UIKit

struct PeptideDetailView: View {
    @Bindable var peptide: Peptide
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingReconstitution = false
    @State private var showingEditVial = false
    @State private var showingLogDose = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSpoilConfirmation = false
    @State private var dosePendingDeletion: DoseEntry?

    private var recentDoses: [DoseEntry] {
        peptide.doseEntries
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        List {
            Section("Schedule") {
                LabeledContent("Type", value: peptide.scheduleType.displayName)
                LabeledContent("Frequency", value: peptide.frequency.displayName)
                LabeledContent("Default Dose", value: "\(Int(peptide.defaultDoseMcg)) mcg")
                Toggle("Active", isOn: $peptide.isActive)
            }

            if peptide.cycleStartDate != nil {
                Section("Cycle") {
                    if let progress = peptide.cycleProgress {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Progress")
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            ProgressView(value: progress)
                                .tint(AppTheme.primary)
                        }
                    }
                    if let days = peptide.cycleDaysRemaining {
                        LabeledContent("Days Remaining", value: "\(days)")
                    }
                    if let end = peptide.cycleEndDate {
                        LabeledContent("Cycle Ends", value: end, format: .dateTime.month().day().year())
                    }
                    if let weeks = peptide.cycleLengthWeeks {
                        LabeledContent("Cycle Length", value: "\(weeks) weeks")
                    }
                }
            }

            Section("Active Vial") {
                if let vial = peptide.activeVial {
                    LabeledContent("Mixed", value: vial.dateMixed, format: .dateTime.month().day().year())
                    LabeledContent("Concentration", value: String(format: "%.0f mcg/mL", vial.concentrationMcgPerML))
                    LabeledContent("Expires", value: vial.expiryDate, format: .dateTime.month().day())
                    LabeledContent("Days Left", value: "\(vial.daysUntilExpiry)")
                    let remaining = vial.estimatedRemainingDoses(forPeptide: peptide)
                    let basisMcg = vial.lastDoseMcg ?? peptide.defaultDoseMcg
                    VStack(alignment: .leading, spacing: 2) {
                        LabeledContent("Doses Remaining", value: "~\(remaining)")
                        Text("Based on last dose: \(Int(basisMcg)) mcg")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    Text("No active vial")
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if peptide.vials.first(where: \.isActive) != nil {
                    Button {
                        showingEditVial = true
                    } label: {
                        Label("Edit Vial", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingSpoilConfirmation = true
                    } label: {
                        Label("Spoil Vial", systemImage: "exclamationmark.triangle")
                    }
                }

                Button {
                    showingReconstitution = true
                } label: {
                    Label("Reconstitute New Vial", systemImage: "drop.fill")
                }
            }

            if !recentDoses.isEmpty {
                Section("Recent Doses") {
                    ForEach(recentDoses) { dose in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(Int(dose.doseMcg)) mcg")
                                    .font(.body.weight(.medium))
                                Spacer()
                                Text(dose.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            if let site = dose.injectionSite {
                                Text(site.displayName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            if let notes = dose.notes {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 2)
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

            if let notes = peptide.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete Peptide", systemImage: "trash")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(peptide.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Log Dose") { showingLogDose = true }
            }
        }
        .sheet(isPresented: $showingReconstitution) {
            ReconstitutionSheet(peptide: peptide)
        }
        .sheet(isPresented: $showingEditVial) {
            if let vial = peptide.vials.first(where: \.isActive) {
                ReconstitutionSheet(peptide: peptide, vial: vial)
            }
        }
        .sheet(isPresented: $showingLogDose) {
            LogDoseSheet(peptide: peptide)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Spoil this vial?",
            isPresented: $showingSpoilConfirmation,
            titleVisibility: .visible
        ) {
            Button("Spoil Vial", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                if let vial = peptide.vials.first(where: \.isActive) {
                    vial.spoiledAt = Date()
                    vial.isActive = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Marks this vial as contaminated or unusable and retires it. Dose history is preserved.")
        }
        .confirmationDialog(
            "Delete \(peptide.name)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Peptide & History", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                NotificationManager.shared.cancelAll(for: peptide)
                modelContext.delete(peptide)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the peptide, all vials, and all dose history. This cannot be undone.")
        }
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
            Text("Removes \(Int(dose.doseMcg))mcg. Any vial volume used by this dose will be returned.")
        }
    }

    private func deleteDose(_ dose: DoseEntry) {
        if let vial = dose.vial {
            vial.totalVolumeUsedML = max(0, vial.totalVolumeUsedML - dose.unitsInjectedML)
        }
        modelContext.delete(dose)
    }
}
