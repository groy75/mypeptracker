import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("syringeType") private var syringeType = "insulin"
    @AppStorage("overdueDelayHours") private var overdueDelayHours = 2.0
    @AppStorage("expiryWarningDays") private var expiryWarningDays = 3
    @AppStorage("preferImperial") private var preferImperial = false
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false

    @Query(sort: \DoseEntry.timestamp) private var allDoses: [DoseEntry]
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
    @Query(sort: \Vial.dateMixed) private var allVials: [Vial]

    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingImportPicker = false
    @State private var importResult: ImportResult?
    @State private var showingImportResult = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Syringe Type") {
                    Picker("Display Units", selection: $syringeType) {
                        Text("Insulin (U-100 / IU)").tag("insulin")
                        Text("Standard (mL)").tag("standard")
                    }
                }

                Section {
                    Toggle("Default new metrics to imperial", isOn: $preferImperial)
                } header: {
                    Text("Body Measurements")
                } footer: {
                    Text("Each metric in Body has its own kg/lb or cm/in toggle. This setting only controls the default for metrics you haven't customized.")
                        .font(.caption2)
                }

                Section("HealthKit") {
                    Toggle("Sync to Apple Health", isOn: $healthKitEnabled)
                        .onChange(of: healthKitEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    let granted = await HealthKitService.shared.requestPermission()
                                    await MainActor.run {
                                        healthKitEnabled = granted
                                    }
                                }
                            }
                        }
                } footer: {
                    Text("Writes weight and body fat % measurements to Apple Health.")
                        .font(.caption2)
                }

                Section("Notifications") {
                    Stepper(
                        "Overdue alert after \(Int(overdueDelayHours))h",
                        value: $overdueDelayHours,
                        in: 1...12,
                        step: 1
                    )
                    Stepper(
                        "Vial expiry warning: \(expiryWarningDays) days",
                        value: $expiryWarningDays,
                        in: 1...14
                    )
                }

                Section("Data") {
                    Button("Export as JSON") {
                        exportData(format: .json)
                    }
                    Button("Export as CSV") {
                        exportData(format: .csv)
                    }
                    Button("Import from JSON or CSV") {
                        showingImportPicker = true
                    }
                }

                Section("Info") {
                    LabeledContent("Peptides", value: "\(allPeptides.count)")
                    LabeledContent("Total Doses Logged", value: "\(allDoses.count)")
                    LabeledContent("Vials Reconstituted", value: "\(allVials.count)")
                }

                Section {
                    NavigationLink("About MyPepTracker") {
                        AboutView()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareLink(item: url)
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json, .plainText, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Import Result", isPresented: $showingImportResult) {
                Button("OK") {}
            } message: {
                if let result = importResult {
                    Text(result.message)
                }
            }
        }
    }

    private let exportService = ExportService()
    private let importService = ImportService()

    private func exportData(format: ExportFormat) {
        if let url = exportService.export(doses: allDoses, format: format) {
            exportURL = url
            showingExportSheet = true
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }

            // Security-scoped resource — start access
            guard url.startAccessingSecurityScopedResource() else {
                importResult = ImportResult(success: false, message: "Could not access the selected file.")
                showingImportResult = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let count: Int
            if url.pathExtension.lowercased() == "json" {
                count = try importService.importJSON(from: url, into: modelContext)
            } else {
                count = try importService.importCSV(from: url, into: modelContext)
            }
            importResult = ImportResult(success: true, message: "Imported \(count) dose entries.")
        } catch let error as ImportError {
            importResult = ImportResult(success: false, message: error.localizedDescription)
        } catch {
            importResult = ImportResult(success: false, message: error.localizedDescription)
        }
        showingImportResult = true
    }
}

private struct ImportResult {
    let success: Bool
    let message: String
}
