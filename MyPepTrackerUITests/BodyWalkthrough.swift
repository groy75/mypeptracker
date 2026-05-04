import XCTest

@MainActor
final class BodyWalkthrough: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += [
            "-lastSeenChangelogBuild", "999",
            "-bodyLayout", "body"  // silhouette by default
        ]
        app.launch()
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: "/tmp/sim-shots"),
            withIntermediateDirectories: true
        )
    }

    func test_walkSilhouette() throws {
        // First flip to list so we can log. (Launch-arg pre-seeded to silhouette.)
        app.tabBars.buttons["Body"].tap()
        _ = app.staticTexts["Body"].waitForExistence(timeout: 3)
        snap("30-silhouette-empty")

        // Switch to list by tapping the leftmost segment (list icon).
        let segments = app.buttons.matching(identifier: "List")
        if segments.count > 0 {
            segments.firstMatch.tap()
            _ = app.staticTexts["Body"].waitForExistence(timeout: 3)
        }

        // Log three metrics so markers have data to render.
        logMetric("Weight", value: "82.0")
        logMetric("Waist", value: "90.0")
        logMetric("Bicep (L)", value: "38.0")

        // Flip back to silhouette — pick the body-icon segment explicitly.
        let bodySegment = app.buttons.matching(identifier: "Body").element(boundBy: 1)
        if bodySegment.waitForExistence(timeout: 2) {
            bodySegment.tap()
            _ = app.staticTexts["Body"].waitForExistence(timeout: 3)
            snap("31-silhouette-with-data")
        }
    }

    private func logMetric(_ name: String, value: String) {
        app.staticTexts[name].firstMatch.tap()
        let recordButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Record your current'")).firstMatch
        XCTAssertTrue(recordButton.waitForExistence(timeout: 3))
        recordButton.tap()
        let field = app.textFields["Value"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap(); field.typeText(value)
        app.buttons["Save"].tap()
        _ = app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 3)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        _ = app.staticTexts["Body"].waitForExistence(timeout: 3)
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let url = URL(fileURLWithPath: "/tmp/sim-shots/\(name).png")
        try? shot.pngRepresentation.write(to: url)
    }

    private func pause(_ seconds: TimeInterval) {
        let exp = expectation(description: "pause")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { exp.fulfill() }
        wait(for: [exp], timeout: seconds + 1)
    }
}
