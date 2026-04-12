import Foundation
import SwiftData

@Model
final class DoseEntry {
    var timestamp: Date
    var doseMcg: Double
    var unitsInjectedML: Double
    var injectionSite: InjectionSite?
    var notes: String?

    var peptide: Peptide?
    var vial: Vial?

    init(
        timestamp: Date = Date(),
        doseMcg: Double,
        unitsInjectedML: Double,
        injectionSite: InjectionSite? = nil,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.doseMcg = doseMcg
        self.unitsInjectedML = unitsInjectedML
        self.injectionSite = injectionSite
        self.notes = notes
    }
}
