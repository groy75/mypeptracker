import Foundation

struct PeptidePreset: Codable, Identifiable {
    var id: String { name }
    let name: String
    let typicalDoseMcgLow: Double
    let typicalDoseMcgHigh: Double
    let typicalVialSizeMg: Double
    let commonFrequency: String
    let category: String
    let typicalCycleWeeks: Int?

    var doseFrequency: DoseFrequency {
        DoseFrequency(rawValue: commonFrequency) ?? .daily
    }

    static func loadAll() throws -> [PeptidePreset] {
        guard let url = Bundle.main.url(forResource: "peptide-presets", withExtension: "json") else {
            throw PresetError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([PeptidePreset].self, from: data)
    }

    static func groupedByCategory(_ presets: [PeptidePreset]) -> [String: [PeptidePreset]] {
        Dictionary(grouping: presets, by: \.category)
    }

    enum PresetError: Error {
        case fileNotFound
    }
}
