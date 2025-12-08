//
//  SplashView.swift
//  Project PawNova
//
//  Animated splash with Aurora theme.
//  Auto-advances after animation completes.
//

import SwiftUI

struct SplashView: View {
    @Environment(OnboardingManager.self) private var onboarding

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            // Aurora glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.pawPrimary.opacity(0.4),
                            Color.pawSecondary.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(glowPulse ? 1.1 : 0.9)
                .opacity(logoOpacity)

            VStack(spacing: 24) {
                // Logo container
                ZStack {
                    // Gradient circle background
                    Circle()
                        .fill(LinearGradient.pawPrimary)
                        .frame(width: 120, height: 120)

                    // Paw icon
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                Text("PawNova")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.pawPrimary)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            animateSplash()
        }
    }

    private func animateSplash() {
        // Phase 1: Logo appears with bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Phase 2: Gentle glow pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }

        // Phase 3: Advance to welcome
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onboarding.nextStep()
        }
    }
}

#Preview {
    SplashView()
        .environment(OnboardingManager())
}
