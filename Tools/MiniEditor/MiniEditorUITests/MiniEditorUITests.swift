//
//  MiniEditorUITests.swift
//  MiniEditorUITests
//
//  Created by Kazuki Nakashima on 2026/04/05.
//

import XCTest

final class MiniEditorUITests: XCTestCase {

    private func headerRadioButton(in app: XCUIApplication) -> XCUIElement {
        app.radioButtons["Header"]
    }

    private func implementationRadioButton(in app: XCUIApplication) -> XCUIElement {
        app.radioButtons["Implementation"]
    }

    private func defaultLightRadioButton(in app: XCUIApplication) -> XCUIElement {
        app.radioButtons["Default (Light)"]
    }

    private func defaultDarkRadioButton(in app: XCUIApplication) -> XCUIElement {
        app.radioButtons["Default (Dark)"]
    }

    private func reloadButton(in app: XCUIApplication) -> XCUIElement {
        app.buttons["reloadButton"]
    }

    private func waitForEditorHarness(_ app: XCUIApplication, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(headerRadioButton(in: app).waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertTrue(implementationRadioButton(in: app).exists, file: file, line: line)
        XCTAssertTrue(defaultLightRadioButton(in: app).exists, file: file, line: line)
        XCTAssertTrue(defaultDarkRadioButton(in: app).exists, file: file, line: line)
        XCTAssertTrue(reloadButton(in: app).exists, file: file, line: line)
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    @MainActor
    func testLaunchesEditorHarness() throws {
        let app = XCUIApplication()
        app.launch()

        waitForEditorHarness(app)
    }

    @MainActor
    func testSwitchesSampleThemeAndReloadsWithoutCrashing() throws {
        let app = XCUIApplication()
        app.launch()

        waitForEditorHarness(app)

        implementationRadioButton(in: app).tap()
        XCTAssertTrue(headerRadioButton(in: app).exists)

        defaultDarkRadioButton(in: app).tap()
        XCTAssertTrue(headerRadioButton(in: app).exists)

        reloadButton(in: app).tap()
        XCTAssertTrue(headerRadioButton(in: app).exists)
    }
}
