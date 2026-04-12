import SwiftUI
import SwiftData

struct PeptideDetailView: View {
    @Bindable var peptide: Peptide
    @State private var showingReconstitution = false
    @State private var showingLogDose = false

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
                    let remaining = vial.estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
                    LabeledContent("Doses Remaining", value: "~\(remaining)")
                } else {
                    Text("No active vial")
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Button("Reconstitute New Vial") {
                    showingReconstitution = true
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
                    }
                }
            }

            if let notes = peptide.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .navigationTitle(peptide.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Log Dose") { showingLogDose = true }
                    .disabled(peptide.activeVial == nil)
            }
        }
        .sheet(isPresented: $showingReconstitution) {
            ReconstitutionSheet(peptide: peptide)
        }
        .sheet(isPresented: $showingLogDose) {
            LogDoseSheet(peptide: peptide)
                .presentationDetents([.medium, .large])
        }
    }
}
