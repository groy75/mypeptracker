import XCTest

/// Smoke-test the Body tab navigation. Regressive case: tapping a metric row
/// used to crash the app via SwiftData's #Predicate traversing an @Model
/// enum's rawValue. If any of these assertions fail, the app almost certainly
/// crashed mid-test (XCUIApplication's state goes .notRunning).
@MainActor
final class BodySmokeTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-screenshotMode", "-lastSeenChangelogBuild", "0"]
        app.launch()
    }

    func test_bodyTabOpensAndWeightDetailDoesNotCrash() throws {
        // Tab bar → Body
        let bodyTab = app.tabBars.buttons["Body"]
        XCTAssertTrue(bodyTab.waitForExistence(timeout: 5), "Body tab not present")
        bodyTab.tap()

        // The list should expose each BodyMetric's displayName. Tap "Weight".
        let weightRow = app.staticTexts["Weight"].firstMatch
        XCTAssertTrue(weightRow.waitForExistence(timeout: 5), "Weight row missing on Body tab")
        weightRow.tap()

        // If we survive that tap and the navigation title shows, the crash is fixed.
        let title = app.navigationBars["Weight"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Weight detail screen did not appear — likely crashed.")

        // Also assert the app process is still alive.
        XCTAssertEqual(app.state, .runningForeground, "App is not foregrounded after navigation — likely crashed.")
    }

    func test_logWeightAndSaveGoalDoesNotCrash() throws {
        // Regression: SetGoalSheet.save() used #Predicate on BodyMetricGoal's
        // metric.rawValue to delete stale goals before inserting. That
        // crashed the same way MetricDetailView's query did.
        app.tabBars.buttons["Body"].tap()

        // Logging is now per-metric: enter Weight detail first, then log there.
        app.staticTexts["Weight"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Weight"].waitForExistence(timeout: 3))

        // Empty-state "Record your current weight" button.
        let recordButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Record your current'")).firstMatch
        XCTAssertTrue(recordButton.waitForExistence(timeout: 3), "Record-current button missing on empty metric")
        recordButton.tap()

        let valueField = app.textFields["Value"].firstMatch
        XCTAssertTrue(valueField.waitForExistence(timeout: 3))
        valueField.tap(); valueField.typeText("82.0")
        app.buttons["Save"].tap()

        // Back on Weight detail (same screen; sheet dismissed).
        XCTAssertTrue(app.navigationBars["Weight"].waitForExistence(timeout: 3))

        // Set a goal.
        app.buttons["Set a goal"].tap()
        XCTAssertTrue(app.navigationBars["Set goal"].waitForExistence(timeout: 3))
        let target = app.textFields.matching(identifier: "Value").element(boundBy: 1)
        XCTAssertTrue(target.waitForExistence(timeout: 3))
        target.tap(); target.typeText("78.0")
        app.buttons["Save"].tap()

        // We must return to the Weight detail, not crash.
        XCTAssertTrue(app.navigationBars["Weight"].waitForExistence(timeout: 5),
                      "Did not return to Weight detail after saving goal — likely crashed.")
        XCTAssertEqual(app.state, .runningForeground, "App crashed while saving goal.")
    }

    func test_silhouetteMarkerNavigatesToMetricDetail() throws {
        // Switch Body tab to silhouette layout and tap the Waist marker.
        app.tabBars.buttons["Body"].tap()

        // Log a weight measurement first so the Weight pill has data
        // (unrelated to the waist marker tap but verifies the pills render).
        app.staticTexts["Weight"].firstMatch.tap()
        let recordButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Record your current'")).firstMatch
        XCTAssertTrue(recordButton.waitForExistence(timeout: 3))
        recordButton.tap()
        let valueField = app.textFields["Value"].firstMatch
        XCTAssertTrue(valueField.waitForExistence(timeout: 3))
        valueField.tap(); valueField.typeText("82.0")
        app.buttons["Save"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap() // back to Body

        // Flip to the silhouette layout.
        app.buttons["Body"].firstMatch.tap()

        // Markers use accessibilityLabel: "<Metric>: ... Double tap to open."
        let waistMarker = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Waist'")).firstMatch
        XCTAssertTrue(waistMarker.waitForExistence(timeout: 3), "Waist marker missing on silhouette")
        waistMarker.tap()

        XCTAssertTrue(app.navigationBars["Waist"].waitForExistence(timeout: 3),
                      "Tapping Waist marker did not open Waist detail")
        XCTAssertEqual(app.state, .runningForeground, "App crashed navigating from silhouette")
    }

    func test_everyMetricOpensWithoutCrashing() throws {
        // Comprehensive: open every metric's detail via silhouette pills or
        // markers and back out. Cheap; fails fast on regressions.
        app.tabBars.buttons["Body"].tap()
        let metrics = [
            "Weight", "Body fat", "Waist", "Neck", "Chest",
            "Back width", "Bicep (L)", "Bicep (R)", "Thigh (L)", "Thigh (R)"
        ]
        for name in metrics {
            // Weight and Body fat are pills above the silhouette — their
            // NavigationLink exposes the metric name as static text. The
            // anatomy metrics are markers whose accessibilityLabel starts
            // with the metric's display name.
            let pill = app.staticTexts[name].firstMatch
            let marker = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(name):")).firstMatch
            let target = pill.exists ? pill : marker
            XCTAssertTrue(target.waitForExistence(timeout: 3), "\(name) pill/marker missing on Body tab")
            target.tap()
            let title = app.navigationBars[name].firstMatch
            XCTAssertTrue(title.waitForExistence(timeout: 3), "\(name) detail did not open")
            XCTAssertEqual(app.state, .runningForeground, "App crashed opening \(name) detail")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
}
