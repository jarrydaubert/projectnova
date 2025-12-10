//
//  StoreServiceTests.swift
//  Project PawNovaTests
//
//  Tests for StoreService and StoreProduct
//

import XCTest
@testable import Project_PawNova

/// Tests for StoreService and StoreProduct.
/// Note: Actual IAP transactions require StoreKit testing configuration.
@MainActor
final class StoreServiceTests: XCTestCase {

    // MARK: - StoreProduct Tests

    func testStoreProduct_MonthlySubscription_Properties() {
        let product = StoreProduct.monthlySubscription
        XCTAssertEqual(product.rawValue, "com.pawnova.subscription.monthly")
        XCTAssertEqual(product.credits, 5000)
        XCTAssertTrue(product.isSubscription)
    }

    func testStoreProduct_AnnualSubscription_Properties() {
        let product = StoreProduct.annualSubscription
        XCTAssertEqual(product.rawValue, "com.pawnova.subscription.annual")
        XCTAssertEqual(product.credits, 5000)
        XCTAssertTrue(product.isSubscription)
    }

    func testStoreProduct_StarterCredits_Properties() {
        let product = StoreProduct.creditsStarter
        XCTAssertEqual(product.rawValue, "com.pawnova.credits.starter")
        XCTAssertEqual(product.credits, 500)
        XCTAssertFalse(product.isSubscription)
    }

    func testStoreProduct_PopularCredits_Properties() {
        let product = StoreProduct.creditsPopular
        XCTAssertEqual(product.rawValue, "com.pawnova.credits.popular")
        XCTAssertEqual(product.credits, 2000)
        XCTAssertFalse(product.isSubscription)
    }

    func testStoreProduct_ProCredits_Properties() {
        let product = StoreProduct.creditsPro
        XCTAssertEqual(product.rawValue, "com.pawnova.credits.pro")
        XCTAssertEqual(product.credits, 6000)
        XCTAssertFalse(product.isSubscription)
    }

    func testStoreProduct_AllCases_Count() {
        XCTAssertEqual(StoreProduct.allCases.count, 5, "Should have 5 product types")
    }

    func testStoreProduct_SubscriptionCount() {
        let subscriptions = StoreProduct.allCases.filter { $0.isSubscription }
        XCTAssertEqual(subscriptions.count, 2, "Should have 2 subscription products")
    }

    func testStoreProduct_CreditPackCount() {
        let creditPacks = StoreProduct.allCases.filter { !$0.isSubscription }
        XCTAssertEqual(creditPacks.count, 3, "Should have 3 credit pack products")
    }

    // MARK: - StoreError Tests

    func testStoreError_VerificationFailed_Description() {
        let error = StoreError.verificationFailed
        XCTAssertEqual(error.errorDescription, "Transaction verification failed")
    }

    func testStoreError_PurchaseFailed_Description() {
        let error = StoreError.purchaseFailed
        XCTAssertEqual(error.errorDescription, "Purchase could not be completed")
    }

    func testStoreError_ProductNotFound_Description() {
        let error = StoreError.productNotFound
        XCTAssertEqual(error.errorDescription, "Product not found")
    }

    // MARK: - StoreService State Tests

    func testStoreService_InitialState() {
        let service = StoreService.shared

        // Initial state checks (before products are loaded)
        XCTAssertFalse(service.isSubscribed, "Should not be subscribed initially")
        XCTAssertNil(service.purchasedSubscription, "Should have no purchased subscription initially")
    }
}
