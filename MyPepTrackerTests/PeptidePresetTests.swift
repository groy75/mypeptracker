import Testing
import Foundation
@testable import MyPepTracker

struct PeptidePresetTests {
    @Test func loadPresetsFromBundle() throws {
        let presets = try PeptidePreset.loadAll()
        #expect(presets.count > 0)
    }

    @Test func presetsHaveRequiredFields() throws {
        let presets = try PeptidePreset.loadAll()
        for preset in presets {
            #expect(!preset.name.isEmpty)
            #expect(preset.typicalDoseMcgLow > 0)
            #expect(preset.typicalDoseMcgHigh >= preset.typicalDoseMcgLow)
            #expect(preset.typicalVialSizeMg > 0)
            #expect(!preset.commonFrequency.isEmpty)
            #expect(!preset.category.isEmpty)
        }
    }

    @Test func presetsGroupByCategory() throws {
        let presets = try PeptidePreset.loadAll()
        let grouped = PeptidePreset.groupedByCategory(presets)
        #expect(grouped.keys.count > 0)
        for (_, items) in grouped {
            #expect(items.count > 0)
        }
    }

    @Test func presetFrequencyMapsToEnum() throws {
        let presets = try PeptidePreset.loadAll()
        for preset in presets {
            let freq = preset.doseFrequency
            #expect(freq.hours > 0)
        }
    }
}
