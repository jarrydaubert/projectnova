//
//  PaywallView.swift
//  Project PawNova
//
//  Subscription paywall - original design.
//  UI-only - wire to RevenueCat later.
//

import SwiftUI

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case yearly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yearly: return "Annual"
        case .monthly: return "Monthly"
        }
    }

    var price: String {
        switch self {
        case .yearly: return "£49.99"
        case .monthly: return "£7.99"
        }
    }

    var perMonth: String {
        switch self {
        case .yearly: return "£4.17/mo"
        case .monthly: return "£7.99/mo"
        }
    }

    var savings: String? {
        switch self {
        case .yearly: return "Save 48%"
        case .monthly: return nil
        }
    }
}

struct PaywallView: View {
    @Environment(OnboardingManager.self) private var onboarding
    @Environment(\.dismiss) private var dismiss

    /// If true, shows X button to dismiss (for sheet presentation outside onboarding)
    var showDismissButton: Bool = false
    /// Optional callback when dismissed without subscribing
    var onDismiss: (() -> Void)?

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isLoading = false
    @State private var contentOpacity: Double = 0

    private let features = [
        ("wand.and.stars", "Unlimited AI video generation"),
        ("film.stack", "Access Veo 3 & Sora 2 models"),
        ("square.and.arrow.up", "Export in Full HD"),
        ("sparkles", "Priority processing")
    ]

    var body: some View {
        ZStack {
            // Aurora background
            auroraBackground

            VStack(spacing: 0) {
                // Dismiss button (when shown as sheet)
                if showDismissButton {
                    HStack {
                        Spacer()
                        Button {
                            Haptic.light()
                            onDismiss?()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.pawTextSecondary)
                        }
                        .padding()
                    }
                }

                // Header
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient.pawPrimary)
                            .frame(width: 70, height: 70)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Unlock PawNova")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.pawTextPrimary)

                    Text("Create stunning pet videos with AI")
                        .font(.subheadline)
                        .foregroundColor(.pawTextSecondary)
                }
                .padding(.top, showDismissButton ? 0 : 40)
                .padding(.bottom, 24)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features, id: \.0) { icon, text in
                        HStack(spacing: 14) {
                            Image(systemName: icon)
                                .font(.body.bold())
                                .foregroundColor(.pawSecondary)
                                .frame(width: 24)

                            Text(text)
                                .font(.subheadline)
                                .foregroundColor(.pawTextPrimary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

                Spacer()

                // Plan selection
                VStack(spacing: 12) {
                    ForEach(SubscriptionPlan.allCases) { plan in
                        planCard(plan)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Subscribe button
                Button {
                    subscribe()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.pawBackground)
                        }
                        Text("Start Subscription")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.pawBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.pawButton)
                    .clipShape(Capsule())
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)

                // Footer
                VStack(spacing: 12) {
                    Text("Cancel anytime in App Store settings")
                        .font(.caption)
                        .foregroundColor(.pawTextSecondary)

                    HStack(spacing: 20) {
                        Button("Restore") { restorePurchases() }
                        Text("•").foregroundColor(.pawTextSecondary.opacity(0.5))
                        Button("Terms") {}
                        Text("•").foregroundColor(.pawTextSecondary.opacity(0.5))
                        Button("Privacy") {}
                    }
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1
            }
        }
    }

    // MARK: - Aurora Background

    private var auroraBackground: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            // Top glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.pawPrimary.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 300)
                .offset(y: -300)

            // Bottom glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.pawSecondary.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 200)
                .offset(x: -50, y: 350)
        }
    }

    // MARK: - Plan Card

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        Button {
            Haptic.selection()
            selectedPlan = plan
        } label: {
            HStack {
                // Selection indicator
                Circle()
                    .strokeBorder(selectedPlan == plan ? Color.pawSecondary : Color.pawTextSecondary.opacity(0.3), lineWidth: 2)
                    .background(
                        Circle()
                            .fill(selectedPlan == plan ? Color.pawSecondary : Color.clear)
                            .padding(4)
                    )
                    .frame(width: 24, height: 24)

                // Plan info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundColor(.pawTextPrimary)

                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption2.bold())
                                .foregroundColor(.pawBackground)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.pawSecondary)
                                .clipShape(Capsule())
                        }
                    }

                    Text(plan.perMonth)
                        .font(.caption)
                        .foregroundColor(.pawTextSecondary)
                }

                Spacer()

                // Price
                Text(plan.price)
                    .font(.title3.bold())
                    .foregroundColor(.pawTextPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pawCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedPlan == plan ? Color.pawSecondary : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func subscribe() {
        isLoading = true
        Haptic.medium()

        // TODO: Wire to RevenueCat
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            onboarding.isSubscribed = true
            Haptic.success()
            onboarding.completeOnboarding()
        }
    }

    private func restorePurchases() {
        Haptic.light()
        // TODO: Wire to RevenueCat
    }
}

#Preview {
    PaywallView()
        .environment(OnboardingManager())
}
