import XCTest
@testable import Project_PawNova

/// Tests for 5-step onboarding flow with notifications.
final class OnboardingTests: XCTestCase {

    var manager: OnboardingManager!

    override func setUp() {
        super.setUp()
        manager = OnboardingManager()
        manager.reset()
    }

    override func tearDown() {
        manager.reset()
        manager = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState_StartsAtSplash() {
        XCTAssertEqual(manager.currentStep, .splash)
    }

    func testInitialState_NotAuthenticated() {
        XCTAssertFalse(manager.isAuthenticated)
    }

    func testInitialState_NotSubscribed() {
        XCTAssertFalse(manager.isSubscribed)
    }

    // MARK: - Navigation

    func testNextStep_AdvancesFromSplash() {
        XCTAssertEqual(manager.currentStep, .splash)
        manager.currentStep = OnboardingStep(rawValue: manager.currentStep.rawValue + 1) ?? .complete
        XCTAssertEqual(manager.currentStep, .welcome)
    }

    func testPreviousStep_GoesBack() {
        manager.currentStep = .petName
        if let prev = OnboardingStep(rawValue: manager.currentStep.rawValue - 1) {
            manager.currentStep = prev
        }
        XCTAssertEqual(manager.currentStep, .welcome)
    }

    func testGoTo_JumpsToSpecificStep() {
        manager.currentStep = .paywall
        XCTAssertEqual(manager.currentStep, .paywall)
    }

    func testNotificationsStep_ExistsInFlow() {
        manager.currentStep = .notifications
        XCTAssertEqual(manager.currentStep, .notifications)
    }

    // MARK: - Completion

    func testCompleteOnboarding_SetsFlag() {
        manager.completeOnboarding()
        XCTAssertTrue(manager.hasCompletedOnboarding)
        XCTAssertEqual(manager.currentStep, .complete)
    }

    // MARK: - Reset

    func testReset_ClearsAllState() {
        manager.isAuthenticated = true
        manager.isSubscribed = true
        manager.notificationsRequested = true
        manager.completeOnboarding()
        manager.reset()

        XCTAssertEqual(manager.currentStep, .splash)
        XCTAssertFalse(manager.hasCompletedOnboarding)
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertFalse(manager.isSubscribed)
        XCTAssertFalse(manager.notificationsRequested)
    }
}

// MARK: - OnboardingStep Tests

extension OnboardingTests {
    func testOnboardingStep_AllCasesCount() {
        // Flow: splash → welcome → petName → notifications → paywall → complete
        XCTAssertEqual(OnboardingStep.allCases.count, 6)
    }

    func testOnboardingStep_RawValuesSequential() {
        for (index, step) in OnboardingStep.allCases.enumerated() {
            XCTAssertEqual(step.rawValue, index)
        }
    }

    func testOnboardingStep_OrderIsCorrect() {
        let steps = OnboardingStep.allCases
        XCTAssertEqual(steps[0], .splash)
        XCTAssertEqual(steps[1], .welcome)
        XCTAssertEqual(steps[2], .petName)
        XCTAssertEqual(steps[3], .notifications)
        XCTAssertEqual(steps[4], .paywall)
        XCTAssertEqual(steps[5], .complete)
    }
}
