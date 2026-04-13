import SwiftUI
import SwiftData

struct ReconstitutionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let peptide: Peptide
    let existingVial: Vial?

    @State private var peptideAmountMg: Double
    @State private var waterVolumeML: Double
    @State private var expiryDays: Int

    private var isEditing: Bool { existingVial != nil }

    init(peptide: Peptide, vial: Vial? = nil) {
        self.peptide = peptide
        self.existingVial = vial
        self._peptideAmountMg = State(initialValue: vial?.peptideAmountMg ?? 5.0)
        self._waterVolumeML = State(initialValue: vial?.waterVolumeML ?? 2.0)
        self._expiryDays = State(initialValue: vial?.expiryDays ?? 30)
    }

    private var concentration: Double {
        guard waterVolumeML > 0 else { return 0 }
        return ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: peptideAmountMg,
            waterVolumeML: waterVolumeML
        )
    }

    private var doseVolume: Double {
        guard concentration > 0 else { return 0 }
        return ConcentrationCalculator.volumeMLForDose(
            doseMcg: peptide.defaultDoseMcg,
            concentrationMcgPerML: concentration
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Peptide Amount") {
                    DoseStepperView(
                        value: $peptideAmountMg,
                        unit: "mg",
                        steps: [1, 5, 10, 25],
                        minimum: 1
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(maxWidth: .infinity)
                }

                Section("BAC Water") {
                    DoseStepperView(
                        value: $waterVolumeML,
                        unit: "mL",
                        steps: [0.5, 1, 2],
                        minimum: 0.5,
                        initialStep: 1
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(maxWidth: .infinity)
                }

                Section("Calculated") {
                    HStack {
                        Text("Concentration")
                        Spacer()
                        Text(String(format: "%.0f mcg/mL", concentration))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    HStack {
                        Text("Per Dose (\(Int(peptide.defaultDoseMcg))mcg)")
                        Spacer()
                        Text(String(format: "%.2f mL (%.0f IU)", doseVolume, ConcentrationCalculator.insulinUnits(fromML: doseVolume)))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    let usedML = existingVial?.totalVolumeUsedML ?? 0
                    let estDoses = concentration > 0
                        ? ConcentrationCalculator.estimatedRemainingDoses(
                            totalVolumeML: waterVolumeML,
                            usedVolumeML: usedML,
                            doseMcg: peptide.defaultDoseMcg,
                            concentrationMcgPerML: concentration
                        )
                        : 0
                    HStack {
                        Text("Estimated Doses")
                        Spacer()
                        Text("~\(estDoses)")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section {
                    Stepper("Expires after \(expiryDays) days", value: $expiryDays, in: 7...90)
                }
            }
            .navigationTitle(isEditing ? "Edit Vial" : "New Vial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveVial() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveVial() {
        if let vial = existingVial {
            // Edit existing
            vial.peptideAmountMg = peptideAmountMg
            vial.waterVolumeML = waterVolumeML
            vial.expiryDays = expiryDays
            NotificationManager.shared.scheduleVialExpiryWarning(for: peptide, vial: vial)
        } else {
            // Create new — deactivate old vials
            for vial in peptide.vials where vial.isActive {
                vial.isActive = false
            }

            let vial = Vial(
                peptideAmountMg: peptideAmountMg,
                waterVolumeML: waterVolumeML,
                expiryDays: expiryDays
            )
            vial.peptide = peptide
            modelContext.insert(vial)

            NotificationManager.shared.scheduleVialExpiryWarning(for: peptide, vial: vial)
        }

        dismiss()
    }
}
