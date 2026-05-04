import XCTest

/// Navigates through the app and captures App Store screenshots.
/// Each screenshot is attached to the test run — extract with:
/// `xcrun xcresulttool get ... --path <xcresult> --format json`
/// or by unpacking the ActivityAttachments in the bundle.
@MainActor
final class ScreenshotTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += [
            "-screenshotMode",
            "-lastSeenChangelogBuild", "0"
        ]
        app.launch()
    }

    // 1 — Hero: Today tab showing both peptide cards with vial gauges
    func test01_TodayGauges() throws {
        app.tabBars.buttons["Today"].tap()
        waitFor(app.staticTexts["Today"])
        snap("01-today-gauges")
    }

    // 2 — Peptide detail: vial header + gauge + titration dose history
    func test02_PeptideDetailGauge() throws {
        app.tabBars.buttons["Peptides"].tap()
        waitFor(app.staticTexts["Retatrutide"])
        app.staticTexts["Retatrutide"].firstMatch.tap()
        waitFor(app.staticTexts["Active Vial"])
        snap("02-peptide-detail-gauge")
    }

    // 3 — Log Dose sheet with mcg slider + live mL / IU readout
    func test03_LogDoseSlider() throws {
        app.tabBars.buttons["Today"].tap()
        waitFor(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log dose for'")).firstMatch)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log dose for'")).firstMatch.tap()
        waitFor(app.navigationBars["Log Retatrutide"])
        snap("03-log-dose-slider")
    }

    // 4 — Reconstitute New Vial: calculator + defaults warning banner
    func test04_ReconstituteNewVial() throws {
        app.tabBars.buttons["Peptides"].tap()
        waitFor(app.staticTexts["Retatrutide"])
        app.staticTexts["Retatrutide"].firstMatch.tap()
        waitFor(app.staticTexts["Active Vial"])
        // Gauge + vial summary push the button below the fold.
        app.swipeUp()
        waitFor(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Reconstitute'")).firstMatch)
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Reconstitute'")).firstMatch.tap()
        waitFor(app.navigationBars["Reconstitute Vial"])
        snap("04-reconstitute-new-vial")
    }

    // 5 — History + injection-site body map
    func test05_HistoryBodyMap() throws {
        app.tabBars.buttons["History"].tap()
        waitFor(app.staticTexts["History"])
        let showSites = app.buttons["Show Injection Sites"]
        if showSites.waitForExistence(timeout: 2) { showSites.tap() }
        waitFor(app.images.firstMatch)
        snap("05-history-body-map")
    }

    // 6 — Settings: HealthKit toggle + Import button (v1.13.0)
    func test06_Settings() throws {
        app.tabBars.buttons["Settings"].tap()
        waitFor(app.staticTexts["Settings"])
        snap("06-settings-v1.13")
    }

    // 7 — What's New / Changelog
    func test07_WhatsNew() throws {
        app.tabBars.buttons["Settings"].tap()
        waitFor(app.staticTexts["Settings"])
        // About is at the bottom of the Settings form — scroll to it.
        app.swipeUp()
        waitFor(app.staticTexts["About MyPepTracker"])
        app.staticTexts["About MyPepTracker"].firstMatch.tap()
        waitFor(app.staticTexts["About"])
        app.staticTexts["What's New"].firstMatch.tap()
        waitFor(app.staticTexts["What's New"])
        snap("07-whats-new")
    }

    // MARK: - Helpers

    private func snap(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Screenshots")
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        let fileURL = dirURL.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
        } catch {
            print("Failed to write screenshot: \(error)")
        }
    }

    /// Waits for an element to exist before proceeding. Replaces fixed sleeps
    /// with explicit existence checks, eliminating flakiness.
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval = 5) {
        _ = element.waitForExistence(timeout: timeout)
    }
}
