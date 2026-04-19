import XCTest

/// Captures screenshots of the Body tab + per-metric unit UX.
/// Not a CI test; used for interactive verification.
@MainActor
final class BodyWalkthrough: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-lastSeenChangelogBuild", "999"]
        app.launch()
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: "/tmp/sim-shots"),
            withIntermediateDirectories: true
        )
    }

    func test_walkNewUX() throws {
        // 1. Body tab — each row shows "Tap to record" for first-time users.
        app.tabBars.buttons["Body"].tap()
        pause(1)
        snap("20-body-empty")

        // 2. Tap Weight → metric detail view with empty-state record button.
        app.staticTexts["Weight"].firstMatch.tap()
        pause(1)
        snap("21-weight-empty-detail")

        // 3. Tap the "Record your current weight" button.
        let recordButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Record your current'")).firstMatch
        recordButton.tap()
        pause(1)
        snap("22-log-sheet-per-metric")

        // 4. Type a value and save.
        let field = app.textFields["Value"].firstMatch
        field.tap(); field.typeText("82.0")
        pause(0.5)
        app.buttons["Save"].tap()
        pause(1)

        // 5. Detail view now shows the value + unit toggle segmented control.
        snap("23-weight-detail-with-value")

        // 6. Toggle to imperial via the unit picker.
        app.buttons["lb"].firstMatch.tap()
        pause(0.8)
        snap("24-weight-detail-imperial")

        // 7. Back to Body list — Weight row shows lb, others in their own prefs.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        pause(0.8)
        snap("25-body-list-per-metric-units")
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let url = URL(fileURLWithPath: "/tmp/sim-shots/\(name).png")
        try? shot.pngRepresentation.write(to: url)
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    private func pause(_ seconds: TimeInterval) {
        let exp = expectation(description: "pause")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { exp.fulfill() }
        wait(for: [exp], timeout: seconds + 1)
    }
}
