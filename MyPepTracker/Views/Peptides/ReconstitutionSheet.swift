import SwiftUI
import SwiftData

/// Sheet for creating or editing a vial reconstitution.
///
/// **Architecture note:** This is the most complex view in the app (340 lines).
/// It mixes UI, guide calculator math, and model mutation. Future refactor:
/// extract the guide math to `ReconstitutionGuideCalculator` and the save
/// workflow to `VialReconstitutionService`.
///
/// **Guide calculator logic:**
/// - User enters desired number of doses (default 20)
/// - App computes recommended BAC water volume targeting 0.1mL per dose
///   (10 IU, easy to measure with a standard syringe)
/// - Concentration and actual dose count are derived from that volume
///
/// **Warning banner:** Orange banner appears until both peptide amount and
/// water volume are explicitly changed from defaults. Prevents accidental
/// saves with placeholder values.
///
/// **Edit mode:** When `existingVial` is non-nil, saving re-computes
/// `unitsInjectedML` for all existing dose entries to match the new
/// concentration. This preserves `doseMcg` (ground truth) while updating
/// the derived volume.
struct ReconstitutionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let peptide: Peptide
    let existingVial: Vial?

    @State private var peptideAmountMg: Double
    @State private var waterVolumeML: Double
    @State private var expiryDays: Int
    @State private var dateMixed: Date
    @State private var showGuide = false
    @State private var desiredDoses: Double = 20
    @State private var hasEditedAmount = false
    @State private var hasEditedWater = false

    private var isEditing: Bool { existingVial != nil }

    init(peptide: Peptide, vial: Vial? = nil) {
        self.peptide = peptide
        self.existingVial = vial
        self._peptideAmountMg = State(initialValue: vial?.peptideAmountMg ?? 5.0)
        self._waterVolumeML = State(initialValue: vial?.waterVolumeML ?? 2.0)
        self._expiryDays = State(initialValue: vial?.expiryDays ?? 30)
        self._dateMixed = State(initialValue: vial?.dateMixed ?? Date())
    }

    private var concentrationChanged: Bool {
        guard let existing = existingVial else { return false }
        return existing.peptideAmountMg != peptideAmountMg || existing.waterVolumeML != waterVolumeML
    }

    private var priorDoseCount: Int {
        existingVial?.doseEntries.count ?? 0
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

    // Guide calculations
    private var guideTotalMcgNeeded: Double {
        peptide.defaultDoseMcg * desiredDoses
    }

    private var guideRecommendedWaterML: Double {
        guard peptideAmountMg > 0, peptide.defaultDoseMcg > 0 else { return 0 }
        // Calculate water needed so each dose draws a clean volume
        // Target: each dose = 0.1mL (10 IU) for easy measuring
        let targetMLPerDose = 0.1
        let totalVolumeNeeded = targetMLPerDose * desiredDoses
        // But can't exceed what the peptide amount supports
        let maxWater = peptideAmountMg * 1000.0 / peptide.defaultDoseMcg * targetMLPerDose
        return min(totalVolumeNeeded, maxWater)
    }

    private var guideConcentration: Double {
        guard guideRecommendedWaterML > 0 else { return 0 }
        return ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: peptideAmountMg,
            waterVolumeML: guideRecommendedWaterML
        )
    }

    private var guideMLPerDose: Double {
        guard guideConcentration > 0 else { return 0 }
        return ConcentrationCalculator.volumeMLForDose(
            doseMcg: peptide.defaultDoseMcg,
            concentrationMcgPerML: guideConcentration
        )
    }

    private var guideActualDoses: Int {
        guard guideMLPerDose > 0 else { return 0 }
        return safeInt(guideRecommendedWaterML / guideMLPerDose)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Reconstitution Guide
                Section {
                    DisclosureGroup("Reconstitution Guide", isExpanded: $showGuide) {
                        VStack(spacing: 16) {
                            // Desired doses stepper
                            HStack {
                                Text("I want")
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Button {
                                        if desiredDoses > 5 { desiredDoses -= 5 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(AppTheme.primary)
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(safeInt(desiredDoses))")
                                        .font(.title3.weight(.semibold).monospacedDigit())
                                        .frame(minWidth: 40)

                                    Button {
                                        desiredDoses += 5
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(AppTheme.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text("doses")
                                    .foregroundStyle(AppTheme.textPrimary)
                            }

                            // Results
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Add this much BAC water")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(String(format: "%.1f mL", guideRecommendedWaterML))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.primary)
                                }
                                HStack {
                                    Text("Concentration")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Spacer()
                                    Text(String(format: "%.0f mcg/mL", guideConcentration))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                HStack {
                                    Text("Each dose draws")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Spacer()
                                    Text(String(format: "%.2f mL (%.0f IU)", guideMLPerDose, ConcentrationCalculator.insulinUnits(fromML: guideMLPerDose)))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                HStack {
                                    Text("Actual doses in vial")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Spacer()
                                    Text("~\(guideActualDoses)")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            .padding(12)
                            .background(AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Apply button
                            Button {
                                withAnimation {
                                    waterVolumeML = (guideRecommendedWaterML * 10).rounded() / 10
                                    showGuide = false
                                }
                            } label: {
                                Text("Use \(String(format: "%.1f", guideRecommendedWaterML)) mL")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.primary)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                }

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

                if !isEditing && !(hasEditedAmount && hasEditedWater) {
                    Section {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            Text("Enter your actual vial amount and water volume. The defaults below may not match what you mixed.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
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
                        Text("Per Dose (\(safeInt(peptide.defaultDoseMcg))mcg)")
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
                    if isEditing {
                        DatePicker("Date Mixed", selection: $dateMixed, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                }

                if isEditing && concentrationChanged && priorDoseCount > 0 {
                    Section {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Concentration is changing")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(priorDoseCount) logged dose\(priorDoseCount == 1 ? "" : "s") on this vial were recorded at the old concentration. Their mcg values won't be recalculated.")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .onChange(of: peptideAmountMg) { hasEditedAmount = true }
            .onChange(of: waterVolumeML) { hasEditedWater = true }
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
            let oldConcentration = vial.concentrationMcgPerML
            vial.peptideAmountMg = peptideAmountMg
            vial.waterVolumeML = waterVolumeML
            vial.expiryDays = expiryDays
            vial.dateMixed = dateMixed
            let newConcentration = vial.concentrationMcgPerML
            // Recompute stored volumes so remaining-dose tracking stays accurate.
            if oldConcentration != newConcentration, newConcentration > 0 {
                for entry in vial.doseEntries {
                    entry.unitsInjectedML = entry.doseMcg / newConcentration
                }
                vial.totalVolumeUsedML = vial.doseEntries.reduce(0) { $0 + $1.unitsInjectedML }
            }
            NotificationManager.shared.scheduleVialExpiryWarning(for: peptide, vial: vial)
        } else {
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
