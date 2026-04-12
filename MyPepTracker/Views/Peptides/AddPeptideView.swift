import SwiftUI
import SwiftData

struct AddPeptideView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var defaultDoseMcg: Double = 250
    @State private var scheduleType: ScheduleType = .fixedRecurring
    @State private var frequency: DoseFrequency = .daily
    @State private var scheduledTime = Calendar.current.date(
        bySettingHour: 8, minute: 0, second: 0, of: Date()
    )!
    @State private var notes = ""
    @State private var selectedPreset: PeptidePreset?
    @State private var showPresets = true

    // Cycle tracking
    @State private var enableCycle = false
    @State private var cycleStartDate = Date()
    @State private var cycleLengthWeeks = 8

    private var presets: [PeptidePreset] {
        (try? PeptidePreset.loadAll()) ?? []
    }

    private var groupedPresets: [String: [PeptidePreset]] {
        PeptidePreset.groupedByCategory(presets)
    }

    var body: some View {
        NavigationStack {
            Form {
                if showPresets && !presets.isEmpty {
                    Section("Quick Start — Pick a Preset") {
                        ForEach(groupedPresets.keys.sorted(), id: \.self) { category in
                            DisclosureGroup(category) {
                                ForEach(groupedPresets[category]!) { preset in
                                    Button {
                                        applyPreset(preset)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preset.name)
                                                .foregroundStyle(AppTheme.textPrimary)
                                            Text("\(Int(preset.typicalDoseMcgLow))–\(Int(preset.typicalDoseMcgHigh))mcg • \(preset.doseFrequency.displayName)")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }
                                }
                            }
                        }

                        Button("Enter Custom Instead") {
                            showPresets = false
                        }
                        .foregroundStyle(AppTheme.primary)
                    }
                }

                Section("Peptide Info") {
                    TextField("Name", text: $name)
                }

                Section("Default Dose") {
                    DoseStepperView(value: $defaultDoseMcg)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(maxWidth: .infinity)
                }

                Section("Schedule") {
                    Picker("Type", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(DoseFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    if scheduleType == .fixedRecurring {
                        DatePicker("Time of Day", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Cycle Tracking") {
                    Toggle("Track a Cycle", isOn: $enableCycle)

                    if enableCycle {
                        DatePicker("Cycle Start", selection: $cycleStartDate, displayedComponents: .date)
                        Stepper("Length: \(cycleLengthWeeks) weeks", value: $cycleLengthWeeks, in: 1...52)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Peptide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePeptide() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func applyPreset(_ preset: PeptidePreset) {
        name = preset.name
        defaultDoseMcg = preset.typicalDoseMcgLow
        frequency = preset.doseFrequency
        if let weeks = preset.typicalCycleWeeks {
            enableCycle = true
            cycleLengthWeeks = weeks
        }
        showPresets = false
        selectedPreset = preset
    }

    private func savePeptide() {
        let peptide = Peptide(
            name: name,
            defaultDoseMcg: defaultDoseMcg,
            scheduleType: scheduleType,
            frequency: frequency,
            scheduledTime: scheduleType == .fixedRecurring ? scheduledTime : nil,
            notes: notes.isEmpty ? nil : notes,
            cycleStartDate: enableCycle ? cycleStartDate : nil,
            cycleLengthWeeks: enableCycle ? cycleLengthWeeks : nil
        )
        modelContext.insert(peptide)

        NotificationManager.shared.scheduleDoseReminder(for: peptide)
        NotificationManager.shared.scheduleOverdueReminder(for: peptide)

        dismiss()
    }
}
