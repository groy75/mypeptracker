import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("syringeType") private var syringeType = "insulin"
    @AppStorage("overdueDelayHours") private var overdueDelayHours = 2.0
    @AppStorage("expiryWarningDays") private var expiryWarningDays = 3

    @Query(sort: \DoseEntry.timestamp) private var allDoses: [DoseEntry]
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
    @Query(sort: \Vial.dateMixed) private var allVials: [Vial]

    @State private var showingExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("Syringe Type") {
                    Picker("Display Units", selection: $syringeType) {
                        Text("Insulin (U-100 / IU)").tag("insulin")
                        Text("Standard (mL)").tag("standard")
                    }
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
        }
    }

    private enum ExportFormat { case json, csv }

    private func exportData(format: ExportFormat) {
        let dateFormatter = ISO8601DateFormatter()
        let fileName = "mypeptracker-export-\(dateFormatter.string(from: Date()))"

        var content: String
        var ext: String

        switch format {
        case .json:
            ext = "json"
            let entries = allDoses.map { dose -> [String: Any] in
                var dict: [String: Any] = [
                    "timestamp": dateFormatter.string(from: dose.timestamp),
                    "doseMcg": dose.doseMcg,
                    "unitsInjectedML": dose.unitsInjectedML,
                    "peptide": dose.peptide?.name ?? "Unknown",
                ]
                if let site = dose.injectionSite { dict["injectionSite"] = site.rawValue }
                if let notes = dose.notes { dict["notes"] = notes }
                return dict
            }
            if let data = try? JSONSerialization.data(withJSONObject: entries, options: .prettyPrinted) {
                content = String(data: data, encoding: .utf8) ?? "[]"
            } else {
                content = "[]"
            }

        case .csv:
            ext = "csv"
            var lines = ["timestamp,peptide,doseMcg,unitsInjectedML,injectionSite,notes"]
            for dose in allDoses {
                let site = dose.injectionSite?.rawValue ?? ""
                let notes = dose.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
                lines.append("\(dateFormatter.string(from: dose.timestamp)),\(dose.peptide?.name ?? "Unknown"),\(dose.doseMcg),\(dose.unitsInjectedML),\(site),\(notes)")
            }
            content = lines.joined(separator: "\n")
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).\(ext)")
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL
        showingExportSheet = true
    }
}
