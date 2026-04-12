import SwiftUI
import SwiftData

struct LogDoseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let peptide: Peptide

    @State private var doseMcg: Double
    @State private var doseDate = Date()
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
                Section {
                    DatePicker("When", selection: $doseDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        Text("Dose")
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

                    Picker("Injection Site", selection: $injectionSite) {
                        Text("None").tag(nil as InjectionSite?)
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site as InjectionSite?)
                        }
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
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
                }
            }
        }
    }

    private func logDose() {
        let vial = peptide.activeVial

        let volumeML: Double
        if let vial {
            volumeML = ConcentrationCalculator.volumeMLForDose(
                doseMcg: doseMcg,
                concentrationMcgPerML: vial.concentrationMcgPerML
            )
        } else {
            volumeML = 0
        }

        let entry = DoseEntry(
            timestamp: doseDate,
            doseMcg: doseMcg,
            unitsInjectedML: volumeML,
            injectionSite: injectionSite,
            notes: notes.isEmpty ? nil : notes
        )
        entry.peptide = peptide
        entry.vial = vial

        if let vial {
            vial.totalVolumeUsedML += volumeML
            let remaining = vial.estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
            NotificationManager.shared.scheduleVialLowWarning(for: peptide, remainingDoses: remaining)
        }

        modelContext.insert(entry)

        let manager = NotificationManager.shared
        manager.scheduleDoseReminder(for: peptide)
        manager.scheduleOverdueReminder(for: peptide)

        dismiss()
    }
}
