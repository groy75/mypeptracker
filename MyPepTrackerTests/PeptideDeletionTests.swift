import Testing
import Foundation
import SwiftData
@testable import MyPepTracker

@MainActor
struct PeptideDeletionTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Peptide.self, Vial.self, DoseEntry.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func makePeptideWithHistory(in context: ModelContext) -> Peptide {
        let peptide = Peptide(
            name: "Test Peptide",
            defaultDoseMcg: 250,
            scheduleType: .fixedRecurring,
            frequency: .daily
        )
        context.insert(peptide)

        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0)
        vial.peptide = peptide
        peptide.vials.append(vial)

        let dose = DoseEntry(doseMcg: 250, unitsInjectedML: 0.1)
        dose.peptide = peptide
        dose.vial = vial
        peptide.doseEntries.append(dose)
        vial.doseEntries.append(dose)

        return peptide
    }

    @Test func deletingPeptideCascadesToVialsAndDoses() throws {
        let context = try makeContext()
        let peptide = makePeptideWithHistory(in: context)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Peptide>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Vial>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<DoseEntry>()) == 1)

        context.delete(peptide)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Peptide>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Vial>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DoseEntry>()) == 0)
    }

    @Test func deletingOnePeptideLeavesOthersIntact() throws {
        let context = try makeContext()
        let doomed = makePeptideWithHistory(in: context)
        let survivor = makePeptideWithHistory(in: context)
        survivor.name = "Survivor"
        try context.save()

        context.delete(doomed)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Peptide>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Vial>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<DoseEntry>()) == 1)

        let remaining = try context.fetch(FetchDescriptor<Peptide>()).first
        #expect(remaining?.name == "Survivor")
    }
}
