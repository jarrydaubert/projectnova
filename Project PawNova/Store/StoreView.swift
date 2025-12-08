//
//  StoreView.swift
//  Project PawNova
//
//  Store interface for subscriptions and credit packs.
//  Dual pricing model: Subscribe OR buy credit packs.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreService.self) private var store

    @State private var selectedTab: StoreTab = .subscription
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum StoreTab: String, CaseIterable {
        case subscription = "Subscribe"
        case credits = "Credit Packs"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pawBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView

                        // Tab picker
                        tabPicker

                        // Content based on tab
                        if selectedTab == .subscription {
                            subscriptionSection
                        } else {
                            creditPacksSection
                        }

                        // Restore purchases
                        restoreButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Get Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.pawTextSecondary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient.pawPrimary)
                    .frame(width: 70, height: 70)

                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Power Your Creativity")
                .font(.title2.bold())
                .foregroundColor(.pawTextPrimary)

            Text("Choose a plan that works for you")
                .font(.subheadline)
                .foregroundColor(.pawTextSecondary)
        }
        .padding(.top)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(StoreTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                    Haptic.selection()
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.bold())
                        .foregroundColor(selectedTab == tab ? .pawBackground : .pawTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab
                                ? LinearGradient.pawButton
                                : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                }
            }
        }
        .background(Color.pawCard)
        .clipShape(Capsule())
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                benefitRow(icon: "infinity", text: "Unlimited video generation")
                benefitRow(icon: "sparkles", text: "5,000 credits every month")
                benefitRow(icon: "bolt.fill", text: "Priority processing")
                benefitRow(icon: "arrow.down.circle", text: "HD video downloads")
            }
            .padding()
            .background(Color.pawCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Subscription options
            ForEach(store.subscriptions, id: \.id) { product in
                subscriptionCard(product)
            }

            // Terms
            Text("Cancel anytime. Subscription renews automatically.")
                .font(.caption)
                .foregroundColor(.pawTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.bold())
                .foregroundColor(.pawSecondary)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.pawTextPrimary)

            Spacer()
        }
    }

    private func subscriptionCard(_ product: Product) -> some View {
        Button {
            Task {
                await purchaseProduct(product)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(.pawTextPrimary)

                        if product.id.contains("annual") {
                            Text("Save 48%")
                                .font(.caption2.bold())
                                .foregroundColor(.pawBackground)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.pawSecondary)
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.pawTextSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundColor(.pawTextPrimary)

                    Text(product.id.contains("annual") ? "/year" : "/month")
                        .font(.caption)
                        .foregroundColor(.pawTextSecondary)
                }
            }
            .padding()
            .background(Color.pawCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        product.id.contains("annual") ? Color.pawSecondary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .disabled(isPurchasing)
    }

    // MARK: - Credit Packs Section

    private var creditPacksSection: some View {
        VStack(spacing: 16) {
            // Info
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.pawSecondary)
                Text("Credits never expire. Use them whenever you want!")
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)
            }
            .padding()
            .background(Color.pawSecondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Credit pack options
            ForEach(store.creditPacks, id: \.id) { product in
                creditPackCard(product)
            }
        }
    }

    private func creditPackCard(_ product: Product) -> some View {
        Button {
            Task {
                await purchaseProduct(product)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(.pawTextPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("\(product.creditsAmount) credits")
                            .font(.caption)
                    }
                    .foregroundColor(.pawSecondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.title3.bold())
                    .foregroundColor(.pawTextPrimary)
            }
            .padding()
            .background(Color.pawCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isPurchasing)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await store.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(.pawTextSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Purchase

    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        Haptic.medium()

        do {
            let success = try await store.purchase(product)
            if success {
                Haptic.success()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptic.error()
        }

        isPurchasing = false
    }
}

#Preview {
    StoreView()
        .environment(StoreService.shared)
}
