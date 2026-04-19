import SwiftUI
import SwiftData
import UIKit

struct LogDoseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

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

    private var sliderMax: Double {
        let base = max(peptide.defaultDoseMcg * 2, 100)
        return max(base, doseMcg + 50)   // keep thumb in range if user steps beyond
    }

    private var sliderStep: Double {
        if sliderMax <= 500 { return 5 }
        if sliderMax <= 5_000 { return 25 }
        return 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DoseStepperView(value: $doseMcg)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Slider(value: $doseMcg, in: 0...sliderMax, step: sliderStep)
                            .tint(AppTheme.primary)
                            .accessibilityLabel("Dose in micrograms")
                            .accessibilityValue("\(Int(doseMcg)) micrograms")
                        HStack {
                            Text("0")
                            Spacer()
                            Text("\(Int(sliderMax)) mcg")
                        }
                        .font(.caption2)
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
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy(duration: 0.15), value: doseMcg)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                Section {
                    DatePicker("When", selection: $doseDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)

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
            let remaining = vial.estimatedRemainingDoses(forPeptide: peptide)
            NotificationManager.shared.scheduleVialLowWarning(for: peptide, remainingDoses: remaining)
        }

        modelContext.insert(entry)

        let manager = NotificationManager.shared
        manager.scheduleDoseReminder(for: peptide)
        manager.scheduleOverdueReminder(for: peptide)

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        appState.showToast("Logged \(Int(doseMcg))mcg of \(peptide.name)")
        appState.selectedTab = .today
        dismiss()
    }
}
