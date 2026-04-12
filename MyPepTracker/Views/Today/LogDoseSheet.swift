import SwiftUI
import SwiftData

struct LogDoseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let peptide: Peptide

    @State private var doseMcg: Double
    @State private var injectionSite: InjectionSite?
    @State private var notes: String = ""

    init(peptide: Peptide) {
        self.peptide = peptide
        self._doseMcg = State(initialValue: peptide.defaultDoseMcg)
        self._injectionSite = State(initialValue: peptide.lastDose?.injectionSite)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dose") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("mcg", value: $doseMcg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mcg")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if let vial = peptide.activeVial {
                        let volumeML = ConcentrationCalculator.volumeMLForDose(
                            doseMcg: doseMcg,
                            concentrationMcgPerML: vial.concentrationMcgPerML
                        )
                        let iu = ConcentrationCalculator.insulinUnits(fromML: volumeML)
                        HStack {
                            Text("Volume")
                            Spacer()
                            Text(String(format: "%.2f mL (%.0f IU)", volumeML, iu))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                Section("Injection Site") {
                    Picker("Site", selection: $injectionSite) {
                        Text("None").tag(nil as InjectionSite?)
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site as InjectionSite?)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional observations...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log \(peptide.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { logDose() }
                        .fontWeight(.semibold)
                        .disabled(peptide.activeVial == nil)
                }
            }
        }
    }

    private func logDose() {
        guard let vial = peptide.activeVial else { return }

        let volumeML = ConcentrationCalculator.volumeMLForDose(
            doseMcg: doseMcg,
            concentrationMcgPerML: vial.concentrationMcgPerML
        )

        let entry = DoseEntry(
            doseMcg: doseMcg,
            unitsInjectedML: volumeML,
            injectionSite: injectionSite,
            notes: notes.isEmpty ? nil : notes
        )
        entry.peptide = peptide
        entry.vial = vial

        vial.totalVolumeUsedML += volumeML

        modelContext.insert(entry)

        let manager = NotificationManager.shared
        manager.scheduleDoseReminder(for: peptide)
        manager.scheduleOverdueReminder(for: peptide)

        let remaining = vial.estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
        manager.scheduleVialLowWarning(for: peptide, remainingDoses: remaining)

        dismiss()
    }
}
