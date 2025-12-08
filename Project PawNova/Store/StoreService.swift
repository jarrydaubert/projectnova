//
//  StoreService.swift
//  Project PawNova
//
//  StoreKit 2 service for subscriptions and credit packs.
//  Handles purchase flow, entitlement verification, and transaction updates.
//

import StoreKit
import SwiftUI
import os

private let logger = Logger(subsystem: "com.pawnova.PawNova", category: "StoreService")

// MARK: - Product Identifiers

enum StoreProduct: String, CaseIterable {
    // Subscriptions
    case monthlySubscription = "com.pawnova.subscription.monthly"
    case annualSubscription = "com.pawnova.subscription.annual"

    // Credit Packs (Consumables)
    case creditsStarter = "com.pawnova.credits.starter"
    case creditsPopular = "com.pawnova.credits.popular"
    case creditsPro = "com.pawnova.credits.pro"

    var credits: Int {
        switch self {
        case .monthlySubscription, .annualSubscription:
            return 5000 // Monthly allocation
        case .creditsStarter:
            return 500
        case .creditsPopular:
            return 2000
        case .creditsPro:
            return 6000
        }
    }

    var isSubscription: Bool {
        switch self {
        case .monthlySubscription, .annualSubscription:
            return true
        case .creditsStarter, .creditsPopular, .creditsPro:
            return false
        }
    }
}

// MARK: - Store Service

@MainActor
@Observable
final class StoreService {
    static let shared = StoreService()

    // Products loaded from App Store
    private(set) var subscriptions: [Product] = []
    private(set) var creditPacks: [Product] = []

    // User state
    private(set) var isSubscribed: Bool = false
    private(set) var purchasedSubscription: Product?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // Transaction listener task
    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load products
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    func cancelListener() {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIds = StoreProduct.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIds)

            // Separate subscriptions and credit packs
            subscriptions = storeProducts.filter { $0.type == .autoRenewable }
                .sorted { $0.price < $1.price }

            creditPacks = storeProducts.filter { $0.type == .consumable }
                .sorted { $0.price < $1.price }

            logger.info("✅ Loaded \(storeProducts.count) products")
        } catch {
            logger.error("❌ Failed to load products: \(error)")
            errorMessage = "Failed to load products"
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)

                // Handle the purchase based on type
                if product.type == .consumable {
                    // Credit pack - add credits
                    if let storeProduct = StoreProduct(rawValue: product.id) {
                        addCredits(storeProduct.credits)
                        logger.info("✅ Added \(storeProduct.credits) credits")
                    }
                } else if product.type == .autoRenewable {
                    // Subscription - update status
                    await updateSubscriptionStatus()
                    // Add monthly credits allocation
                    if let storeProduct = StoreProduct(rawValue: product.id) {
                        addCredits(storeProduct.credits)
                    }
                }

                // Finish the transaction
                await transaction.finish()
                isLoading = false
                return true

            case .userCancelled:
                logger.info("ℹ️ User cancelled purchase")
                isLoading = false
                return false

            case .pending:
                logger.info("ℹ️ Purchase pending (Ask to Buy)")
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            logger.error("❌ Purchase failed: \(error)")
            errorMessage = "Purchase failed"
            isLoading = false
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            logger.info("✅ Restored purchases")
        } catch {
            logger.error("❌ Restore failed: \(error)")
            errorMessage = "Failed to restore purchases"
        }

        isLoading = false
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        // Check for active subscription
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productType == .autoRenewable {
                isSubscribed = true
                purchasedSubscription = subscriptions.first { $0.id == transaction.productID }

                // Persist to UserDefaults for offline access
                UserDefaults.standard.set(true, forKey: "isSubscribed")
                logger.info("✅ Active subscription: \(transaction.productID)")
                return
            }
        }

        // No active subscription
        isSubscribed = false
        purchasedSubscription = nil
        UserDefaults.standard.set(false, forKey: "isSubscribed")
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)

                    // Update UI on main actor
                    await MainActor.run {
                        Task {
                            await self?.updateSubscriptionStatus()
                        }
                    }

                    await transaction.finish()
                } catch {
                    logger.error("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Credits Management

    private func addCredits(_ amount: Int) {
        let currentCredits = UserDefaults.standard.integer(forKey: "userCredits")
        let newCredits = currentCredits + amount
        UserDefaults.standard.set(newCredits, forKey: "userCredits")
        logger.info("✅ Credits updated: \(currentCredits) → \(newCredits)")
    }
}

// MARK: - Store Error

enum StoreError: LocalizedError {
    case verificationFailed
    case purchaseFailed
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase could not be completed"
        case .productNotFound:
            return "Product not found"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    var displayPriceFormatted: String {
        displayPrice
    }

    var creditsAmount: Int {
        StoreProduct(rawValue: id)?.credits ?? 0
    }
}
