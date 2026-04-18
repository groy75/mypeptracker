import Testing
import Foundation
import SwiftData
@testable import MyPepTracker

@MainActor
struct DoseDeletionTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Peptide.self, Vial.self, DoseEntry.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func makeTrio(in context: ModelContext, usedML: Double = 0.5, doseML: Double = 0.1) -> (Peptide, Vial, DoseEntry) {
        let peptide = Peptide(name: "Test", defaultDoseMcg: 250, scheduleType: .fixedRecurring, frequency: .daily)
        context.insert(peptide)

        let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0, totalVolumeUsedML: usedML)
        vial.peptide = peptide
        peptide.vials.append(vial)

        let dose = DoseEntry(doseMcg: 250, unitsInjectedML: doseML)
        dose.peptide = peptide
        dose.vial = vial
        peptide.doseEntries.append(dose)
        vial.doseEntries.append(dose)

        return (peptide, vial, dose)
    }

    @Test func deletingDoseRollsBackVialVolume() throws {
        let context = try makeContext()
        let (_, vial, dose) = makeTrio(in: context, usedML: 0.5, doseML: 0.1)
        try context.save()

        #expect(vial.totalVolumeUsedML == 0.5)

        // Simulate the view's deleteDose behavior
        vial.totalVolumeUsedML = max(0, vial.totalVolumeUsedML - dose.unitsInjectedML)
        context.delete(dose)
        try context.save()

        #expect(vial.totalVolumeUsedML == 0.4)
        #expect(try context.fetchCount(FetchDescriptor<DoseEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Vial>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Peptide>()) == 1)
    }

    @Test func deletingDoseClampsUsedVolumeToZero() throws {
        let context = try makeContext()
        // Simulate out-of-sync state: dose volume exceeds recorded usage
        let (_, vial, dose) = makeTrio(in: context, usedML: 0.05, doseML: 0.1)
        try context.save()

        vial.totalVolumeUsedML = max(0, vial.totalVolumeUsedML - dose.unitsInjectedML)
        context.delete(dose)
        try context.save()

        #expect(vial.totalVolumeUsedML == 0)
    }

    @Test func deletingDoseWithoutVialIsSafe() throws {
        let context = try makeContext()
        let peptide = Peptide(name: "Test", defaultDoseMcg: 250, scheduleType: .fixedRecurring, frequency: .daily)
        context.insert(peptide)
        let dose = DoseEntry(doseMcg: 250, unitsInjectedML: 0.1)
        dose.peptide = peptide
        peptide.doseEntries.append(dose)
        try context.save()

        context.delete(dose)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<DoseEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Peptide>()) == 1)
    }
}
