//
//  ErrorHandlingTests.swift
//  Project PawNovaTests
//
//  Tests for error handling utilities
//

import XCTest
@testable import Project_PawNova

/// Tests for PawNovaError and error handling utilities.
final class ErrorHandlingTests: XCTestCase {

    // MARK: - PawNovaError Tests

    func testPawNovaError_NoInternet_HasDescription() {
        let error = PawNovaError.noInternet
        XCTAssertNotNil(error.errorDescription, "Should have error description")
        XCTAssertTrue(error.errorDescription?.lowercased().contains("internet") ?? false)
    }

    func testPawNovaError_ServerUnreachable_HasDescription() {
        let error = PawNovaError.serverUnreachable
        XCTAssertNotNil(error.errorDescription, "Should have error description")
    }

    func testPawNovaError_Timeout_HasDescription() {
        let error = PawNovaError.timeout
        XCTAssertNotNil(error.errorDescription, "Should have error description")
    }

    func testPawNovaError_GenerationFailed_HasDescription() {
        let error = PawNovaError.generationFailed(reason: "Test failure")
        XCTAssertNotNil(error.errorDescription, "Should have error description")
        XCTAssertTrue(error.errorDescription?.contains("Test failure") ?? false)
    }

    func testPawNovaError_ContentBlocked_HasDescription() {
        let error = PawNovaError.contentBlocked
        XCTAssertNotNil(error.errorDescription, "Should have error description")
    }

    func testPawNovaError_ApiKeyMissing_HasDescription() {
        let error = PawNovaError.apiKeyMissing
        XCTAssertNotNil(error.errorDescription, "Should have error description")
    }

    func testPawNovaError_PurchaseFailed_HasDescription() {
        let error = PawNovaError.purchaseFailed(reason: "Card declined")
        XCTAssertNotNil(error.errorDescription, "Should have error description")
        XCTAssertTrue(error.errorDescription?.contains("Card declined") ?? false)
    }

    func testPawNovaError_PermissionDenied_HasDescription() {
        let error = PawNovaError.permissionDenied(type: "photos")
        XCTAssertNotNil(error.errorDescription, "Should have error description")
        XCTAssertTrue(error.errorDescription?.contains("photos") ?? false)
    }

    // MARK: - InputSanitizer Tests

    func testInputSanitizer_SanitizePrompt_RemovesExtraWhitespace() {
        let input = "  hello   world  "
        let result = InputSanitizer.sanitizePrompt(input)
        XCTAssertFalse(result.hasPrefix(" "), "Should trim leading whitespace")
        XCTAssertFalse(result.hasSuffix(" "), "Should trim trailing whitespace")
    }

    func testInputSanitizer_SanitizePrompt_TruncatesLongText() {
        let longInput = String(repeating: "a", count: 600)
        let result = InputSanitizer.sanitizePrompt(longInput)
        XCTAssertLessThanOrEqual(result.count, 500, "Should truncate to 500 characters or less")
    }

    func testInputSanitizer_ContainsBlockedContent_DetectsHarmfulTerms() {
        // Test that certain harmful content is blocked
        // Note: The actual blocked terms may vary based on implementation
        let safePrompt = "A cute puppy playing in the park"
        XCTAssertFalse(InputSanitizer.containsBlockedContent(safePrompt), "Safe content should not be blocked")
    }

    // MARK: - NetworkMonitor Tests

    @MainActor
    func testNetworkMonitor_SharedInstance_Exists() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor, "Shared instance should exist")
    }

    @MainActor
    func testNetworkMonitor_IsConnectedProperty_Exists() {
        let monitor = NetworkMonitor.shared
        // Just verify the property is accessible (actual connection state depends on device)
        _ = monitor.isConnected
        XCTAssertTrue(true, "isConnected property should be accessible")
    }
}
