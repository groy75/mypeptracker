import Foundation
import SwiftData

enum ImportError: Error, Sendable {
    case invalidFormat
    case missingRequiredField(String)
    case invalidDate(String)
    case invalidNumber(String)
    case unknownPeptide(String)
    case unknownInjectionSite(String)
}

/// Imports dose entries from JSON or CSV files. Creates missing peptides
/// automatically (using the name as-is with sensible defaults).
@MainActor
struct ImportService {
    /// Imports doses from a JSON file.
    /// Expected format: array of objects with keys:
    ///   timestamp (ISO8601), peptide (string), doseMcg (number),
    ///   unitsInjectedML (number, optional), injectionSite (string, optional),
    ///   notes (string, optional)
    func importJSON(from url: URL, into context: ModelContext) throws -> Int {
        let data = try Data(contentsOf: url)
        guard let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ImportError.invalidFormat
        }
        return try importEntries(entries, into: context)
    }

    /// Imports doses from a CSV file.
    /// Expected columns: timestamp, peptide, doseMcg, unitsInjectedML, injectionSite, notes
    func importCSV(from url: URL, into context: ModelContext) throws -> Int {
        let content = try String(contentsOf: url, encoding: .utf8)
        var lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw ImportError.invalidFormat }
        lines.removeFirst() // skip header

        let dateFormatter = ISO8601DateFormatter()
        var entries: [[String: Any]] = []

        for line in lines where !line.isEmpty {
            let cols = line.components(separatedBy: ",")
            guard cols.count >= 3 else { continue }

            guard let timestamp = dateFormatter.date(from: cols[0]) else {
                throw ImportError.invalidDate(cols[0])
            }
            guard let doseMcg = Double(cols[2]) else {
                throw ImportError.invalidNumber(cols[2])
            }

            var dict: [String: Any] = [
                "timestamp": timestamp,
                "peptide": cols[1],
                "doseMcg": doseMcg,
            ]
            if cols.count > 3, let units = Double(cols[3]) {
                dict["unitsInjectedML"] = units
            }
            if cols.count > 4, !cols[4].isEmpty {
                dict["injectionSite"] = cols[4]
            }
            if cols.count > 5, !cols[5].isEmpty {
                dict["notes"] = cols[5]
            }
            entries.append(dict)
        }

        return try importEntries(entries, into: context)
    }

    private func importEntries(_ entries: [[String: Any]], into context: ModelContext) throws -> Int {
        // Pre-fetch all peptides to avoid N+1 lookups
        let allPeptides = try context.fetch(FetchDescriptor<Peptide>())
        var peptideMap: [String: Peptide] = Dictionary(
            uniqueKeysWithValues: allPeptides.map { ($0.name.lowercased(), $0) }
        )

        var count = 0
        for entry in entries {
            guard let peptideName = entry["peptide"] as? String else {
                throw ImportError.missingRequiredField("peptide")
            }
            guard let timestamp = entry["timestamp"] as? Date else {
                throw ImportError.missingRequiredField("timestamp")
            }
            guard let doseMcg = entry["doseMcg"] as? Double else {
                throw ImportError.missingRequiredField("doseMcg")
            }

            let peptide: Peptide
            let key = peptideName.lowercased()
            if let existing = peptideMap[key] {
                peptide = existing
            } else {
                // Create a placeholder peptide with sensible defaults
                peptide = Peptide(
                    name: peptideName,
                    defaultDoseMcg: doseMcg,
                    scheduleType: .afterDose,
                    frequency: .daily
                )
                context.insert(peptide)
                peptideMap[key] = peptide
            }

            let units = entry["unitsInjectedML"] as? Double ?? 0
            let site: InjectionSite? = (entry["injectionSite"] as? String)
                .flatMap { InjectionSite(rawValue: $0) }
            let notes = entry["notes"] as? String

            let dose = DoseEntry(
                timestamp: timestamp,
                doseMcg: doseMcg,
                unitsInjectedML: units,
                injectionSite: site,
                notes: notes
            )
            dose.peptide = peptide
            peptide.doseEntries.append(dose)
            context.insert(dose)
            count += 1
        }

        try context.save()
        return count
    }
}
