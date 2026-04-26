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
            // Force UserDefaults to deterministic values each run. On iOS,
            // passing "-<key> <value>" on the command line populates UserDefaults
            // for the session only.
            "-lastSeenChangelogBuild", "0"
        ]
        app.launch()
    }

    // 1 — Hero: Reconstitute New Vial
    func test01_ReconstituteNewVial() throws {
        app.tabBars.buttons["Peptides"].tap()
        // First row = Retatrutide (seeded alphabetically)
        app.staticTexts["Retatrutide"].firstMatch.tap()
        app.buttons["Reconstitute New Vial"].tap()
        wait(0.6)
        snap("01-reconstitute-new-vial")
    }

    // 2 — Today tab with both peptide cards
    func test02_TodayOverview() throws {
        if !app.tabBars.buttons["Today"].isSelected {
            app.tabBars.buttons["Today"].tap()
        }
        wait(0.4)
        snap("02-today-overview")
    }

    // 3 — Log Dose sheet with slider + live IU
    func test03_LogDoseSlider() throws {
        app.tabBars.buttons["Today"].tap()
        // The Log Dose button label we set is "Log dose for {name}"
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log dose for'")).firstMatch.tap()
        wait(0.8)
        snap("03-log-dose-slider")
    }

    // 4 — Peptide detail
    func test04_PeptideDetail() throws {
        app.tabBars.buttons["Peptides"].tap()
        app.staticTexts["Selank"].firstMatch.tap()
        wait(0.4)
        snap("04-peptide-detail")
    }

    // 5 — History + body map
    func test05_HistoryBodyMap() throws {
        app.tabBars.buttons["History"].tap()
        wait(0.3)
        // The "Show Injection Sites" button reveals the body map.
        let showSites = app.buttons["Show Injection Sites"]
        if showSites.exists { showSites.tap() }
        wait(0.5)
        snap("05-history-body-map")
    }

    // 6 — What's New / Changelog
    func test06_WhatsNew() throws {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["About MyPepTracker"].tap()
        app.buttons["What's New"].tap()
        wait(0.4)
        snap("06-whats-new")
    }

    // MARK: - Helpers

    private func snap(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
            try? screenshot.pngRepresentation.write(to: url)
        }
    }

    private func wait(_ seconds: TimeInterval) {
        let exp = expectation(description: "pause")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { exp.fulfill() }
        wait(for: [exp], timeout: seconds + 1)
    }
}
