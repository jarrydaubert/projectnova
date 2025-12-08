//
//  Project_PawNovaUITests.swift
//  Project PawNovaUITests
//
//  E2E UI tests for PawNova app using XCUITest.
//  Tests cover onboarding, video generation, library, and settings flows.
//

import XCTest

final class Project_PawNovaUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Reset onboarding state for clean test runs
        app.launchArguments = ["-resetOnboarding", "YES"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        app.launch()
        // App should launch without crashing
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Onboarding Flow Tests

    @MainActor
    func testOnboarding_SplashScreen_AutoAdvances() throws {
        app.launch()

        // Splash screen should show PawNova logo
        let splashExists = app.staticTexts["PawNova"].waitForExistence(timeout: 2)
        XCTAssertTrue(splashExists, "Splash screen should show PawNova title")

        // Should auto-advance to welcome (wait up to 5 seconds)
        let welcomeButton = app.buttons["Continue with Apple"]
        let welcomeAppears = welcomeButton.waitForExistence(timeout: 5)
        XCTAssertTrue(welcomeAppears, "Should auto-advance to welcome screen")
    }

    @MainActor
    func testOnboarding_WelcomeScreen_HasSignInOptions() throws {
        app.launch()

        // Wait for welcome screen
        let appleButton = app.buttons["Continue with Apple"]
        _ = appleButton.waitForExistence(timeout: 6)

        // Check sign-in options exist
        XCTAssertTrue(appleButton.exists, "Apple sign-in button should exist")

        // Check skip option exists (for demo mode)
        let skipButton = app.buttons["Skip for now"]
        XCTAssertTrue(skipButton.exists, "Skip button should exist for demo mode")
    }

    @MainActor
    func testOnboarding_SkipLogin_AdvancesToPetName() throws {
        app.launch()

        // Wait for and tap skip
        let skipButton = app.buttons["Skip for now"]
        _ = skipButton.waitForExistence(timeout: 6)
        skipButton.tap()

        // Should show pet name screen
        let petNameField = app.textFields.firstMatch
        let petNameAppears = petNameField.waitForExistence(timeout: 3)
        XCTAssertTrue(petNameAppears, "Should advance to pet name screen")
    }

    @MainActor
    func testOnboarding_EnterPetName_AdvancesToNotifications() throws {
        app.launch()

        // Skip login
        let skipButton = app.buttons["Skip for now"]
        _ = skipButton.waitForExistence(timeout: 6)
        skipButton.tap()

        // Enter pet name
        let petNameField = app.textFields.firstMatch
        _ = petNameField.waitForExistence(timeout: 3)
        petNameField.tap()
        petNameField.typeText("Fluffy")

        // Tap continue
        let continueButton = app.buttons["Continue"]
        continueButton.tap()

        // Should show notifications screen
        let notificationsText = app.staticTexts["Stay Updated"]
        let notificationsAppears = notificationsText.waitForExistence(timeout: 3)
        XCTAssertTrue(notificationsAppears, "Should advance to notifications screen")
    }

    @MainActor
    func testOnboarding_CompleteFlow_ReachesMainApp() throws {
        app.launch()

        // Skip login
        let skipButton = app.buttons["Skip for now"]
        _ = skipButton.waitForExistence(timeout: 6)
        skipButton.tap()

        // Enter pet name
        let petNameField = app.textFields.firstMatch
        _ = petNameField.waitForExistence(timeout: 3)
        petNameField.tap()
        petNameField.typeText("Test Pet")

        let continueButton = app.buttons["Continue"]
        continueButton.tap()

        // Skip notifications (tap "Maybe Later" if it exists)
        let maybeLater = app.buttons["Maybe Later"]
        if maybeLater.waitForExistence(timeout: 3) {
            maybeLater.tap()
        }

        // Handle paywall - skip for testing
        let skipPaywall = app.buttons["Skip"]
        if skipPaywall.waitForExistence(timeout: 3) {
            skipPaywall.tap()
        }

        // Should show main tab view with Create tab
        let createTab = app.tabBars.buttons["Create"]
        let mainAppReached = createTab.waitForExistence(timeout: 5)
        XCTAssertTrue(mainAppReached, "Should reach main app after onboarding")
    }

    // MARK: - Main Tab Navigation Tests

    @MainActor
    func testMainApp_TabNavigation_Works() throws {
        launchToMainApp()

        // Verify Create tab is selected by default
        let createTab = app.tabBars.buttons["Create"]
        XCTAssertTrue(createTab.isSelected, "Create tab should be selected by default")

        // Navigate to Library
        let libraryTab = app.tabBars.buttons["Library"]
        libraryTab.tap()
        XCTAssertTrue(libraryTab.isSelected, "Library tab should be selected")

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected")

        // Navigate back to Create
        createTab.tap()
        XCTAssertTrue(createTab.isSelected, "Create tab should be re-selected")
    }

    // MARK: - Create Video Flow Tests

    @MainActor
    func testCreateTab_HasRequiredElements() throws {
        launchToMainApp()

        // Check for prompt text field/editor
        let promptField = app.textViews.firstMatch
        XCTAssertTrue(promptField.exists, "Prompt input should exist")

        // Check for model selector
        let modelPicker = app.buttons.matching(identifier: "ModelSelector").firstMatch
        let hasModelSelector = modelPicker.exists || app.staticTexts["Fast Paws"].exists
        XCTAssertTrue(hasModelSelector, "Model selector should exist")

        // Check for generate button
        let generateButton = app.buttons["Generate Video"]
        XCTAssertTrue(generateButton.exists, "Generate button should exist")
    }

    @MainActor
    func testCreateTab_EnterPrompt_UpdatesUI() throws {
        launchToMainApp()

        // Find and tap prompt field
        let promptField = app.textViews.firstMatch
        promptField.tap()

        // Type a prompt
        promptField.typeText("A cute cat playing with yarn")

        // Verify text was entered
        XCTAssertTrue(promptField.value as? String == "A cute cat playing with yarn" ||
                     app.staticTexts["A cute cat playing with yarn"].exists,
                     "Prompt should be entered")
    }

    @MainActor
    func testCreateTab_GenerateButton_RequiresPrompt() throws {
        launchToMainApp()

        // Find generate button
        let generateButton = app.buttons["Generate Video"]

        // Button should be disabled without prompt
        XCTAssertFalse(generateButton.isEnabled, "Generate should be disabled without prompt")
    }

    @MainActor
    func testCreateTab_WithPrompt_GenerateButtonEnabled() throws {
        launchToMainApp()

        // Enter prompt
        let promptField = app.textViews.firstMatch
        promptField.tap()
        promptField.typeText("A happy dog running in park")

        // Generate button should be enabled
        let generateButton = app.buttons["Generate Video"]
        XCTAssertTrue(generateButton.isEnabled, "Generate should be enabled with prompt")
    }

    // MARK: - Library Tab Tests

    @MainActor
    func testLibraryTab_ShowsEmptyState() throws {
        launchToMainApp()

        // Navigate to Library
        let libraryTab = app.tabBars.buttons["Library"]
        libraryTab.tap()

        // Should show empty state message
        let emptyState = app.staticTexts["No videos yet"]
        let hasEmptyState = emptyState.waitForExistence(timeout: 2)
        XCTAssertTrue(hasEmptyState, "Library should show empty state")
    }

    @MainActor
    func testLibraryTab_HasFilterOptions() throws {
        launchToMainApp()

        // Navigate to Library
        let libraryTab = app.tabBars.buttons["Library"]
        libraryTab.tap()

        // Check for filter buttons
        let allButton = app.buttons["All"]
        let favoritesButton = app.buttons["Favorites"]

        XCTAssertTrue(allButton.exists, "All filter should exist")
        XCTAssertTrue(favoritesButton.exists, "Favorites filter should exist")
    }

    // MARK: - Settings Tab Tests

    @MainActor
    func testSettingsTab_HasRequiredSections() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Wait for settings to load
        sleep(1)

        // Check for key sections
        let subscriptionSection = app.staticTexts["Subscription"]
        let storageSection = app.staticTexts["Storage"]
        let notificationsSection = app.staticTexts["Notifications"]
        let supportSection = app.staticTexts["Support"]

        XCTAssertTrue(subscriptionSection.exists, "Subscription section should exist")
        XCTAssertTrue(storageSection.exists, "Storage section should exist")
        XCTAssertTrue(notificationsSection.exists, "Notifications section should exist")
        XCTAssertTrue(supportSection.exists, "Support section should exist")
    }

    @MainActor
    func testSettingsTab_ShowsVideoCount() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Check for video count display
        let videosCreated = app.staticTexts["Videos Created"]
        XCTAssertTrue(videosCreated.exists, "Videos Created label should exist")
    }

    @MainActor
    func testSettingsTab_HasUpgradeButton() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Check for upgrade button
        let upgradeButton = app.buttons["Upgrade"]
        XCTAssertTrue(upgradeButton.exists, "Upgrade button should exist")
    }

    @MainActor
    func testSettingsTab_NotificationSettings_Exist() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Check for notification row
        let notificationsLabel = app.staticTexts["Notifications"]
        XCTAssertTrue(notificationsLabel.exists, "Notifications setting should exist")
    }

    @MainActor
    func testSettingsTab_DeleteAllVideos_ShowsConfirmation() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Scroll to find delete button
        let deleteButton = app.buttons["Delete All Videos"]
        if deleteButton.exists {
            deleteButton.tap()

            // Should show confirmation alert
            let alert = app.alerts["Delete All Videos?"]
            let alertAppears = alert.waitForExistence(timeout: 2)
            XCTAssertTrue(alertAppears, "Delete confirmation alert should appear")

            // Cancel the alert
            app.alerts.buttons["Cancel"].tap()
        }
    }

    // MARK: - Store/Payment Flow Tests

    @MainActor
    func testSettingsTab_UpgradeButton_OpensStore() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Tap upgrade
        let upgradeButton = app.buttons["Upgrade"]
        upgradeButton.tap()

        // Store view should appear
        let storeTitle = app.staticTexts["Get Credits"]
        let storeAppears = storeTitle.waitForExistence(timeout: 3)
        XCTAssertTrue(storeAppears, "Store view should open")
    }

    @MainActor
    func testStoreView_HasSubscriptionAndCreditTabs() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store
        let upgradeButton = app.buttons["Upgrade"]
        upgradeButton.tap()

        // Wait for store to load
        _ = app.staticTexts["Get Credits"].waitForExistence(timeout: 3)

        // Check for tab options
        let subscribeTab = app.buttons["Subscribe"]
        let creditsTab = app.buttons["Credit Packs"]

        XCTAssertTrue(subscribeTab.exists, "Subscribe tab should exist")
        XCTAssertTrue(creditsTab.exists, "Credit Packs tab should exist")
    }

    @MainActor
    func testStoreView_CanSwitchBetweenTabs() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store
        app.buttons["Upgrade"].tap()
        _ = app.staticTexts["Get Credits"].waitForExistence(timeout: 3)

        // Switch to Credit Packs
        let creditsTab = app.buttons["Credit Packs"]
        creditsTab.tap()

        // Verify credit packs content shows
        let creditsInfo = app.staticTexts["Credits never expire"]
        _ = creditsInfo.waitForExistence(timeout: 2)
        XCTAssertTrue(creditsInfo.exists, "Credit packs info should be visible")
    }

    @MainActor
    func testStoreView_HasRestorePurchasesButton() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store
        app.buttons["Upgrade"].tap()
        _ = app.staticTexts["Get Credits"].waitForExistence(timeout: 3)

        // Check for restore button
        let restoreButton = app.buttons["Restore Purchases"]
        XCTAssertTrue(restoreButton.exists, "Restore Purchases button should exist")
    }

    @MainActor
    func testStoreView_CloseButton_DismissesStore() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store
        app.buttons["Upgrade"].tap()
        _ = app.staticTexts["Get Credits"].waitForExistence(timeout: 3)

        // Close store
        let closeButton = app.buttons["Close"]
        closeButton.tap()

        // Should be back to settings
        let settingsTitle = app.navigationBars["Settings"]
        let backToSettings = settingsTitle.waitForExistence(timeout: 2)
        XCTAssertTrue(backToSettings, "Should return to Settings after closing store")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testAccessibility_MainTabsHaveLabels() throws {
        launchToMainApp()

        let createTab = app.tabBars.buttons["Create"]
        let libraryTab = app.tabBars.buttons["Library"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(createTab.isHittable, "Create tab should be accessible")
        XCTAssertTrue(libraryTab.isHittable, "Library tab should be accessible")
        XCTAssertTrue(settingsTab.isHittable, "Settings tab should be accessible")
    }

    // MARK: - Helper Methods

    /// Launches the app and navigates through onboarding to reach main app
    private func launchToMainApp() {
        // Launch with arguments to skip onboarding or mark as completed
        app.launchArguments = ["-skipOnboarding", "YES"]
        app.launch()

        // Wait for main app to appear
        let createTab = app.tabBars.buttons["Create"]
        if !createTab.waitForExistence(timeout: 8) {
            // If onboarding shows, complete it
            completeOnboardingIfNeeded()
        }
    }

    /// Completes onboarding flow if it appears
    private func completeOnboardingIfNeeded() {
        // Skip login
        let skipButton = app.buttons["Skip for now"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
        }

        // Enter pet name
        let petNameField = app.textFields.firstMatch
        if petNameField.waitForExistence(timeout: 2) {
            petNameField.tap()
            petNameField.typeText("Test")
            app.buttons["Continue"].tap()
        }

        // Skip notifications
        let maybeLater = app.buttons["Maybe Later"]
        if maybeLater.waitForExistence(timeout: 2) {
            maybeLater.tap()
        }

        // Skip paywall
        let skipPaywall = app.buttons["Skip"]
        if skipPaywall.waitForExistence(timeout: 2) {
            skipPaywall.tap()
        }
    }
}

// MARK: - Video Generation Tests (Requires Demo Mode)

extension Project_PawNovaUITests {

    @MainActor
    func testDemoMode_GenerateVideo_ShowsProgress() throws {
        launchToMainApp()

        // Enter prompt
        let promptField = app.textViews.firstMatch
        promptField.tap()
        promptField.typeText("A cute puppy")

        // Tap generate
        let generateButton = app.buttons["Generate Video"]
        if generateButton.isEnabled {
            generateButton.tap()

            // Should show loading/progress indicator
            let progressIndicator = app.activityIndicators.firstMatch
            let generating = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Generating'")).firstMatch
            let showsProgress = progressIndicator.waitForExistence(timeout: 3) || generating.waitForExistence(timeout: 3)

            XCTAssertTrue(showsProgress, "Should show progress during generation")
        }
    }
}
