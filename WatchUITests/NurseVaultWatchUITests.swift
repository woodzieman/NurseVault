import XCTest

/// UI tests for the watch app: per-section and global search over the
/// documents (added by the iOS tests and synced via CloudKit).
///
/// `@MainActor`: XCTest's UI APIs are main-actor-isolated; running the
/// test body on the main actor keeps the build warning-free.
@MainActor final class NurseVaultWatchUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Each test (re)creates the app object: XCUIAutomation's APIs are
    /// main-actor-isolated, and the base-class `setUpWithError` can't be
    /// (the override must keep its non-isolated signature), while the test
    /// methods themselves are main-actor via the class annotation.
    private func attachApp() {
        app = XCUIApplication(bundleIdentifier: "com.josephwoods.nursevault.watchkitapp")
    }

    private func tapRow(_ name: String) {
        var row = app.buttons[name].firstMatch
        if !row.waitForExistence(timeout: 10) {
            row = app.staticTexts[name].firstMatch
        }
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Row \(name) not found")
        row.tap()
        sleep(1)
    }

    /// The PDF imported on the phone syncs to the watch; its title should be
    /// found in search. Retries with app relaunches to tolerate a slow sync.
    private func expectSearchHit(_ query: String, in scope: String) {
        for attempt in 0..<3 {
            if attempt > 0 {
                // A fresh launch starts on an empty search field, so no
                // clearing is needed (and clearText()/pressHome() are not
                // available on watchOS).
                app.terminate()
                app.launch()
                sleep(2)
                if scope == "section" {
                    tapRow("Drugs")
                } else {
                    tapRow("Search")
                }
            }
            let field = app.textFields.firstMatch
            if !field.waitForExistence(timeout: 10) { continue }
            field.tap()
            field.typeText(query)
            let hit = app.staticTexts["Amiodarone"].firstMatch
            if hit.waitForExistence(timeout: 20) {
                print("WATCH_\(scope.uppercased())_SEARCH: pass (attempt \(attempt + 1))")
                return
            }
        }
        XCTFail("WATCH_\(scope.uppercased())_SEARCH: no match for \"\(query)\" after 3 attempts")
    }

    func test01_sectionSearch() throws {
        attachApp()
        // Terminate first so launch() can't resume a restored detail view.
        app.terminate()
        app.launch()
        tapRow("Drugs")
        expectSearchHit("Amiodarone", in: "section")
    }

    func test02_globalSearch() throws {
        attachApp()
        app.terminate()
        app.launch()
        tapRow("Search")
        expectSearchHit("Amiodarone", in: "global")
    }
}
