import Foundation

enum ExportFormat {
    case json
    case csv
}

struct ExportService {
    private let dateFormatter: ISO8601DateFormatter

    init() {
        self.dateFormatter = ISO8601DateFormatter()
    }

    /// Exports dose entries to a temporary file and returns its URL.
    /// - Parameters:
    ///   - doses: The dose entries to export
    ///   - format: JSON or CSV
    /// - Returns: URL to the temporary file, or nil if serialization failed
    func export(doses: [DoseEntry], format: ExportFormat) -> URL? {
        let fileName = "mypeptracker-export-\(dateFormatter.string(from: Date()))"

        let content: String
        let ext: String

        switch format {
        case .json:
            ext = "json"
            content = exportJSON(doses: doses)
        case .csv:
            ext = "csv"
            content = exportCSV(doses: doses)
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).\(ext)")

        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    private func exportJSON(doses: [DoseEntry]) -> String {
        let entries = doses.map { dose -> [String: Any] in
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

        guard let data = try? JSONSerialization.data(withJSONObject: entries, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    private func exportCSV(doses: [DoseEntry]) -> String {
        var lines = ["timestamp,peptide,doseMcg,unitsInjectedML,injectionSite,notes"]
        for dose in doses {
            let site = dose.injectionSite?.rawValue ?? ""
            let notes = dose.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            lines.append("\(dateFormatter.string(from: dose.timestamp)),\(dose.peptide?.name ?? "Unknown"),\(dose.doseMcg),\(dose.unitsInjectedML),\(site),\(notes)")
        }
        return lines.joined(separator: "\n")
    }
}
