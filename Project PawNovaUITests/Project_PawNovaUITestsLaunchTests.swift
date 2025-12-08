//
//  Project_PawNovaUITestsLaunchTests.swift
//  Project PawNovaUITests
//
//  Launch tests for PawNova app.
//  Captures screenshots at launch for App Store submissions.
//

import XCTest

final class Project_PawNovaUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchWithSkippedOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "YES"]
        app.launch()

        // Wait for main app to appear
        let createTab = app.tabBars.buttons["Create"]
        _ = createTab.waitForExistence(timeout: 5)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Main App - Create Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchLibraryTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "YES"]
        app.launch()

        // Navigate to Library
        let libraryTab = app.tabBars.buttons["Library"]
        _ = libraryTab.waitForExistence(timeout: 5)
        libraryTab.tap()

        sleep(1) // Wait for animation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Main App - Library Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchSettingsTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "YES"]
        app.launch()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        _ = settingsTab.waitForExistence(timeout: 5)
        settingsTab.tap()

        sleep(1) // Wait for animation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Main App - Settings Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
