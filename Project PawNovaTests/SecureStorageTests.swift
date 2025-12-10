//
//  SecureStorageTests.swift
//  Project PawNovaTests
//
//  Tests for SecureUserData Keychain storage
//

import XCTest
@testable import Project_PawNova

/// Tests for SecureUserData - the Keychain-backed secure storage singleton.
/// These tests verify credits management, subscription status, and reset functionality.
@MainActor
final class SecureStorageTests: XCTestCase {

    private var secureData: SecureUserData!

    override func setUp() async throws {
        try await super.setUp()
        secureData = SecureUserData.shared
        // Note: We don't reset in setUp to avoid affecting the singleton state during parallel test runs
        // Tests should be designed to work with current state or use delta assertions
    }

    // MARK: - Credits Tests

    func testSecureUserData_AddCredits_IncreasesBalance() {
        // Given
        let initialCredits = secureData.credits
        let addAmount = 100

        // When
        secureData.addCredits(addAmount)

        // Then
        XCTAssertEqual(secureData.credits, initialCredits + addAmount, "Credits should increase by added amount")

        // Cleanup - restore original
        secureData.setCredits(initialCredits)
    }

    func testSecureUserData_DeductCredits_DecreasesBalance() {
        // Given
        let initialCredits = secureData.credits
        let deductAmount = min(50, initialCredits) // Don't deduct more than we have

        // When
        let success = secureData.deductCredits(deductAmount)

        // Then
        XCTAssertTrue(success, "Deduction should succeed when sufficient credits available")
        XCTAssertEqual(secureData.credits, initialCredits - deductAmount, "Credits should decrease by deducted amount")

        // Cleanup - restore original
        secureData.setCredits(initialCredits)
    }

    func testSecureUserData_DeductCredits_FailsWhenInsufficient() {
        // Given
        let initialCredits = secureData.credits
        secureData.setCredits(10)
        let largeDeduction = 1000

        // When
        let success = secureData.deductCredits(largeDeduction)

        // Then
        XCTAssertFalse(success, "Deduction should fail when insufficient credits")
        XCTAssertEqual(secureData.credits, 10, "Credits should remain unchanged after failed deduction")

        // Cleanup - restore original
        secureData.setCredits(initialCredits)
    }

    func testSecureUserData_SetCredits_UpdatesValue() {
        // Given
        let initialCredits = secureData.credits
        let newValue = 999

        // When
        secureData.setCredits(newValue)

        // Then
        XCTAssertEqual(secureData.credits, newValue, "Credits should be set to exact value")

        // Cleanup - restore original
        secureData.setCredits(initialCredits)
    }

    func testSecureUserData_SetCredits_NegativeBecomesZero() {
        // Given
        let initialCredits = secureData.credits

        // When
        secureData.setCredits(-100)

        // Then
        XCTAssertEqual(secureData.credits, 0, "Negative credits should be clamped to zero")

        // Cleanup - restore original
        secureData.setCredits(initialCredits)
    }

    // MARK: - Subscription Tests

    func testSecureUserData_SetSubscribed_UpdatesStatus() {
        // Given
        let initialStatus = secureData.isSubscribed

        // When
        secureData.setSubscribed(true)

        // Then
        XCTAssertTrue(secureData.isSubscribed, "Subscription status should be true after setting")

        // When
        secureData.setSubscribed(false)

        // Then
        XCTAssertFalse(secureData.isSubscribed, "Subscription status should be false after setting")

        // Cleanup - restore original
        secureData.setSubscribed(initialStatus)
    }

    // MARK: - Reset Tests

    func testSecureUserData_ResetAll_ClearsAllData() {
        // Given - set some values first
        let initialCredits = secureData.credits
        let initialSubscribed = secureData.isSubscribed
        secureData.setCredits(500)
        secureData.setSubscribed(true)
        secureData.setUserId("test-user-123")

        // When
        secureData.resetAll()

        // Then
        XCTAssertEqual(secureData.credits, 0, "Credits should be reset to 0")
        XCTAssertFalse(secureData.isSubscribed, "Subscription should be reset to false")
        XCTAssertNil(secureData.userId, "User ID should be cleared")

        // Restore to reasonable defaults for other tests
        secureData.setCredits(initialCredits > 0 ? initialCredits : 5000)
        secureData.setSubscribed(initialSubscribed)
    }

    // MARK: - User ID Tests

    func testSecureUserData_SetUserId_StoresValue() {
        // Given
        let testUserId = "test-user-\(UUID().uuidString)"

        // When
        secureData.setUserId(testUserId)

        // Then
        XCTAssertEqual(secureData.userId, testUserId, "User ID should be stored")

        // Cleanup
        secureData.setUserId(nil)
    }

    func testSecureUserData_SetUserId_NilClearsValue() {
        // Given
        secureData.setUserId("some-user-id")

        // When
        secureData.setUserId(nil)

        // Then
        XCTAssertNil(secureData.userId, "User ID should be cleared when set to nil")
    }
}
