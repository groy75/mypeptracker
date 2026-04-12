import SwiftUI
import SwiftData

struct ReconstitutionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let peptide: Peptide

    @State private var peptideAmountMg: Double = 5.0
    @State private var waterVolumeML: Double = 2.0
    @State private var expiryDays: Int = 30

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
                Section("Vial Contents") {
                    HStack {
                        Text("Peptide Amount")
                        Spacer()
                        TextField("mg", value: $peptideAmountMg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mg")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    HStack {
                        Text("BAC Water")
                        Spacer()
                        TextField("mL", value: $waterVolumeML, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mL")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
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

                    let estDoses = concentration > 0
                        ? ConcentrationCalculator.estimatedRemainingDoses(
                            totalVolumeML: waterVolumeML,
                            usedVolumeML: 0,
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
            .navigationTitle("New Vial")
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

        dismiss()
    }
}
