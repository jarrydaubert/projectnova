//
//  OnboardingContainerView.swift
//  Project PawNova
//
//  5-step onboarding container.
//  Splash → Welcome+Auth → Pet Name → Notifications → Paywall
//

import SwiftUI

struct OnboardingContainerView: View {
    @Environment(OnboardingManager.self) private var onboarding

    var body: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            switch onboarding.currentStep {
            case .splash:
                SplashView()
                    .transition(.opacity)

            case .welcome:
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .petName:
                PetNameView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .notifications:
                NotificationsView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .paywall:
                PaywallView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))

            case .complete:
                // Handled by parent - show main app
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboarding.currentStep)
    }
}

#Preview {
    OnboardingContainerView()
        .environment(OnboardingManager())
}
