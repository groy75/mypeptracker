import SwiftUI
import SwiftData

struct AddPeptideView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var defaultDoseMcg: Double = 250
    @State private var scheduleType: ScheduleType = .fixedRecurring
    @State private var frequencyHours: Double = 24
    @State private var scheduledTime = Calendar.current.date(
        bySettingHour: 8, minute: 0, second: 0, of: Date()
    )!
    @State private var notes = ""
    @State private var selectedPreset: PeptidePreset?
    @State private var showPresets = true

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
                                            Text("\(Int(preset.typicalDoseMcgLow))–\(Int(preset.typicalDoseMcgHigh))mcg • \(Int(preset.commonFrequencyHours))hr")
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
                    HStack {
                        Text("Default Dose")
                        Spacer()
                        TextField("mcg", value: $defaultDoseMcg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mcg")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section("Schedule") {
                    Picker("Type", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    HStack {
                        Text("Every")
                        Spacer()
                        TextField("hours", value: $frequencyHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("hours")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if scheduleType == .fixedRecurring {
                        DatePicker("Time of Day", selection: $scheduledTime, displayedComponents: .hourAndMinute)
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
        frequencyHours = preset.commonFrequencyHours
        showPresets = false
        selectedPreset = preset
    }

    private func savePeptide() {
        let peptide = Peptide(
            name: name,
            defaultDoseMcg: defaultDoseMcg,
            scheduleType: scheduleType,
            frequencyHours: frequencyHours,
            scheduledTime: scheduleType == .fixedRecurring ? scheduledTime : nil,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(peptide)

        NotificationManager.shared.scheduleDoseReminder(for: peptide)
        NotificationManager.shared.scheduleOverdueReminder(for: peptide)

        dismiss()
    }
}
