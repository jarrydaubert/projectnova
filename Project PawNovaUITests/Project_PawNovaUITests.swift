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

        // Check skip option exists (for dev/demo mode - DEBUG builds only)
        let skipButton = app.buttons["Skip (Dev Mode)"]
        XCTAssertTrue(skipButton.exists, "Skip button should exist for demo mode")
    }

    @MainActor
    func testOnboarding_SkipLogin_AdvancesToPetName() throws {
        app.launch()

        // Wait for and tap skip (Dev Mode button)
        let skipButton = app.buttons["Skip (Dev Mode)"]
        _ = skipButton.waitForExistence(timeout: 6)
        skipButton.tap()

        // Should show pet name screen - look for the title text or the text field
        let petNameTitle = app.staticTexts["What's your pet's name?"]
        let petNameField = app.textFields["Enter your pet's name"]
        let petNameAppears = petNameTitle.waitForExistence(timeout: 5) || petNameField.waitForExistence(timeout: 5)
        XCTAssertTrue(petNameAppears, "Should advance to pet name screen")
    }

    @MainActor
    func testOnboarding_EnterPetName_AdvancesToNotifications() throws {
        app.launch()

        // Skip login (Dev Mode button)
        let skipButton = app.buttons["Skip (Dev Mode)"]
        _ = skipButton.waitForExistence(timeout: 6)
        skipButton.tap()

        // Wait for pet name screen
        let petNameField = app.textFields["Enter your pet's name"]
        _ = petNameField.waitForExistence(timeout: 5)
        petNameField.tap()
        petNameField.typeText("Fluffy")

        // Tap continue
        let continueButton = app.buttons["Continue"]
        _ = continueButton.waitForExistence(timeout: 2)
        continueButton.tap()

        // Should show notifications screen - title is "Stay in the Loop"
        let notificationsText = app.staticTexts["Stay in the Loop"]
        let notificationsAppears = notificationsText.waitForExistence(timeout: 5)
        XCTAssertTrue(notificationsAppears, "Should advance to notifications screen")
    }

    @MainActor
    func testOnboarding_CompleteFlow_ReachesMainApp() throws {
        app.launch()

        // Skip login (Dev Mode button)
        let skipButton = app.buttons["Skip (Dev Mode)"]
        _ = skipButton.waitForExistence(timeout: 6)
        skipButton.tap()

        // Wait for pet name screen - look for the title first
        let petNameTitle = app.staticTexts["What's your pet's name?"]
        _ = petNameTitle.waitForExistence(timeout: 5)

        // Use "Skip for now" to skip pet name entry (fastest path through onboarding)
        let skipPetName = app.buttons["Skip for now"]
        if skipPetName.waitForExistence(timeout: 2) {
            skipPetName.tap()
        }

        // Skip notifications (tap "Maybe Later" if it exists)
        let maybeLater = app.buttons["Maybe Later"]
        if maybeLater.waitForExistence(timeout: 3) {
            maybeLater.tap()
        }

        // Handle paywall - tap "Start Subscription" or close button to continue
        // In test environment, this should proceed through the flow
        let closeButton = app.buttons["Close"]
        let startSubscription = app.buttons["Start Subscription"]
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        } else if startSubscription.waitForExistence(timeout: 2) {
            startSubscription.tap()
            sleep(2)
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

        // Verify Projects tab is selected by default (home tab)
        let projectsTab = app.tabBars.buttons["Projects"]
        XCTAssertTrue(projectsTab.isSelected, "Projects tab should be selected by default")

        // Navigate to Create
        let createTab = app.tabBars.buttons["Create"]
        createTab.tap()
        XCTAssertTrue(createTab.isSelected, "Create tab should be selected")

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected")

        // Navigate back to Projects
        projectsTab.tap()
        XCTAssertTrue(projectsTab.isSelected, "Projects tab should be re-selected")
    }

    // MARK: - Create Video Flow Tests

    @MainActor
    func testCreateTab_HasRequiredElements() throws {
        launchToMainApp()

        // Navigate to Create tab (default is now Projects)
        let createTab = app.tabBars.buttons["Create"]
        createTab.tap()

        // Check for prompt text field (TextField, not TextView)
        let promptField = app.textFields.firstMatch
        XCTAssertTrue(promptField.exists, "Prompt input should exist")

        // Check for model selector - look for "Fast Paws" which is the default model display name
        let hasModelSelector = app.staticTexts["Fast Paws"].exists || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Fast Paws'")).firstMatch.exists
        XCTAssertTrue(hasModelSelector, "Model selector should exist")

        // Check for generate button (now called "Create Adventure")
        let generateButton = app.buttons["Create Adventure"]
        XCTAssertTrue(generateButton.exists, "Generate button should exist")
    }

    @MainActor
    func testCreateTab_EnterPrompt_UpdatesUI() throws {
        launchToMainApp()

        // Navigate to Create tab
        let createTab = app.tabBars.buttons["Create"]
        createTab.tap()

        // Find and tap prompt field (TextField, not TextView)
        let promptField = app.textFields.firstMatch
        _ = promptField.waitForExistence(timeout: 3)
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

        // Navigate to Create tab
        let createTab = app.tabBars.buttons["Create"]
        createTab.tap()

        // Find generate button (now called "Create Adventure")
        let generateButton = app.buttons["Create Adventure"]
        _ = generateButton.waitForExistence(timeout: 3)

        // Button should be disabled without prompt
        XCTAssertFalse(generateButton.isEnabled, "Generate should be disabled without prompt")
    }

    @MainActor
    func testCreateTab_WithPrompt_GenerateButtonEnabled() throws {
        launchToMainApp()

        // Navigate to Create tab
        let createTab = app.tabBars.buttons["Create"]
        createTab.tap()

        // Enter prompt (TextField, not TextView)
        let promptField = app.textFields.firstMatch
        _ = promptField.waitForExistence(timeout: 3)
        promptField.tap()
        promptField.typeText("A happy dog running in park")

        // Generate button should be enabled (now called "Create Adventure")
        let generateButton = app.buttons["Create Adventure"]
        _ = generateButton.waitForExistence(timeout: 2)
        XCTAssertTrue(generateButton.isEnabled, "Generate should be enabled with prompt")
    }

    // MARK: - Projects Tab Tests

    @MainActor
    func testProjectsTab_ShowsEmptyStateOrVideos() throws {
        launchToMainApp()

        // Projects tab is default, should already be showing
        // Could show empty state OR video grid depending on data state

        // Empty state indicators
        let emptyStateTitle = app.staticTexts["Ready to create amazing\nvideos?"]
        let createFirstVideoButton = app.buttons["Create Your First Video"]
        let seeExamplesButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'See Examples'")).firstMatch

        // Populated state indicators - header "Create Video" button always exists
        let createVideoHeaderButton = app.buttons["Create Video"]

        // Wait for view to load then check content
        _ = createVideoHeaderButton.waitForExistence(timeout: 3)

        // Should have either empty state content or the header Create Video button
        let hasExpectedContent = emptyStateTitle.exists ||
                                 createFirstVideoButton.exists ||
                                 seeExamplesButton.exists ||
                                 createVideoHeaderButton.exists

        XCTAssertTrue(hasExpectedContent, "Projects should show empty state or video content")
    }

    @MainActor
    func testProjectsTab_HasCreateVideoButton() throws {
        launchToMainApp()

        // Projects tab is default, should already be showing
        // Check for "Create Video" button in the header area
        let createVideoButton = app.buttons["Create Video"]
        let hasCreateVideoButton = createVideoButton.waitForExistence(timeout: 2)
        XCTAssertTrue(hasCreateVideoButton, "Create Video button should exist")
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

        // Check for upgrade button - it's part of a combined label button
        // The button label is "PawNova Pro, Unlimited videos, HD export, Upgrade"
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade'")).firstMatch
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

        // Tap upgrade - it's part of a combined label button
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade'")).firstMatch
        _ = upgradeButton.waitForExistence(timeout: 2)
        upgradeButton.tap()

        // Store/Paywall view should appear - look for common paywall elements
        let paywallElements = [
            app.staticTexts["PawNova Pro"],
            app.staticTexts["Unlock PawNova Pro"],
            app.buttons["Subscribe Now"]
        ]
        let storeAppears = paywallElements.contains { $0.waitForExistence(timeout: 3) }
        XCTAssertTrue(storeAppears, "Store/Paywall view should open")
    }

    @MainActor
    func testStoreView_HasSubscriptionOptions() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store - using combined label button
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade'")).firstMatch
        _ = upgradeButton.waitForExistence(timeout: 2)
        upgradeButton.tap()

        // Wait for paywall to load - look for "Unlock PawNova" title or "Start Subscription" button
        let paywallLoaded = app.staticTexts["Unlock PawNova"].waitForExistence(timeout: 3) ||
                           app.buttons["Start Subscription"].waitForExistence(timeout: 3)

        XCTAssertTrue(paywallLoaded, "Paywall should load with subscription options")
    }

    @MainActor
    func testStoreView_HasFeaturesList() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store - using combined label button
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade'")).firstMatch
        _ = upgradeButton.waitForExistence(timeout: 2)
        upgradeButton.tap()

        // Wait for paywall to load
        _ = app.staticTexts["Unlock PawNova"].waitForExistence(timeout: 3) ||
            app.buttons["Start Subscription"].waitForExistence(timeout: 3)

        // Verify features list shows (from PaywallView features array)
        let featureTexts = [
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Unlimited'")).firstMatch,
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'HD'")).firstMatch
        ]
        let hasFeatures = featureTexts.contains { $0.exists }
        XCTAssertTrue(hasFeatures, "Paywall should show feature list")
    }

    @MainActor
    func testStoreView_HasCloseButton() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store - using combined label button
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade'")).firstMatch
        _ = upgradeButton.waitForExistence(timeout: 2)
        upgradeButton.tap()

        // Wait for paywall to load
        _ = app.staticTexts["Unlock PawNova"].waitForExistence(timeout: 3) ||
            app.buttons["Start Subscription"].waitForExistence(timeout: 3)

        // Check for close button (xmark.circle.fill with label "Close")
        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.exists, "Close button should exist in paywall")
    }

    @MainActor
    func testStoreView_CloseButton_DismissesStore() throws {
        launchToMainApp()

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        // Open store - using combined label button
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade'")).firstMatch
        _ = upgradeButton.waitForExistence(timeout: 2)
        upgradeButton.tap()

        // Wait for paywall to load
        _ = app.staticTexts["Unlock PawNova"].waitForExistence(timeout: 3) ||
            app.buttons["Start Subscription"].waitForExistence(timeout: 3)

        // Close store using Close button (xmark.circle.fill)
        let closeButton = app.buttons["Close"]
        _ = closeButton.waitForExistence(timeout: 2)
        closeButton.tap()

        // Should be back to settings - check for Settings navigation bar
        let settingsTitle = app.navigationBars["Settings"]
        let backToSettings = settingsTitle.waitForExistence(timeout: 2)
        XCTAssertTrue(backToSettings, "Should return to Settings after closing paywall")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testAccessibility_MainTabsHaveLabels() throws {
        launchToMainApp()

        let projectsTab = app.tabBars.buttons["Projects"]
        let createTab = app.tabBars.buttons["Create"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(projectsTab.isHittable, "Projects tab should be accessible")
        XCTAssertTrue(createTab.isHittable, "Create tab should be accessible")
        XCTAssertTrue(settingsTab.isHittable, "Settings tab should be accessible")
    }

    // MARK: - Helper Methods

    /// Launches the app and navigates through onboarding to reach main app
    private func launchToMainApp() {
        // Launch with arguments to skip onboarding or mark as completed
        app.launchArguments = ["-skipOnboarding", "YES"]
        app.launch()

        // Wait for main app to appear (Projects tab is now the default/home tab)
        let projectsTab = app.tabBars.buttons["Projects"]
        if !projectsTab.waitForExistence(timeout: 8) {
            // If onboarding shows, complete it
            completeOnboardingIfNeeded()
        }
    }

    /// Completes onboarding flow if it appears
    private func completeOnboardingIfNeeded() {
        // Skip login (Dev Mode button)
        let skipButton = app.buttons["Skip (Dev Mode)"]
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
    func testDemoMode_GenerateVideo_ShowsConfirmationOrPaywall() throws {
        launchToMainApp()

        // Navigate to Create tab
        let createTab = app.tabBars.buttons["Create"]
        createTab.tap()

        // Enter prompt (TextField, not TextView)
        let promptField = app.textFields.firstMatch
        _ = promptField.waitForExistence(timeout: 3)
        promptField.tap()
        promptField.typeText("A cute puppy")

        // Tap generate (now called "Create Adventure")
        let generateButton = app.buttons["Create Adventure"]
        _ = generateButton.waitForExistence(timeout: 2)
        if generateButton.isEnabled {
            generateButton.tap()

            // After tapping Create Adventure, depending on subscription state:
            // 1. Non-subscribers: Paywall sheet shows ("Unlock PawNova Pro" in PaywallSheetView)
            // 2. Subscribers with insufficient credits: "Insufficient Credits" alert
            // 3. Subscribers with enough credits: "Create Video?" confirmation alert
            // 4. After confirmation: Progress indicator and "Creating Magic..." text
            let paywallSheetTitle = app.staticTexts["Unlock PawNova Pro"]
            let paywallOnboardingTitle = app.staticTexts["Unlock PawNova"]
            let insufficientCreditsAlert = app.alerts["Insufficient Credits"]
            let confirmAlert = app.alerts["Create Video?"]
            let createButton = app.alerts.buttons["Create"]
            let progressIndicator = app.activityIndicators.firstMatch
            let creating = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Creating'")).firstMatch

            let showsExpectedUI = paywallSheetTitle.waitForExistence(timeout: 3) ||
                                  paywallOnboardingTitle.exists ||
                                  insufficientCreditsAlert.exists ||
                                  confirmAlert.exists ||
                                  createButton.exists ||
                                  progressIndicator.exists ||
                                  creating.exists

            XCTAssertTrue(showsExpectedUI, "Should show paywall, credits alert, confirmation, or progress after tapping generate")
        }
    }
}
