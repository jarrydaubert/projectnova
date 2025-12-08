//
//  NotificationsView.swift
//  Project PawNova
//
//  Push notification permissions request screen.
//  Best practice: explain value before requesting.
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @Environment(OnboardingManager.self) private var onboarding

    @State private var contentOpacity: Double = 0
    @State private var isRequesting = false

    private let benefits = [
        ("bell.badge.fill", "Video Ready", "Get notified when your video finishes generating"),
        ("star.fill", "New Features", "Be the first to know about new AI models"),
        ("gift.fill", "Special Offers", "Exclusive discounts and bonus credits")
    ]

    var body: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button {
                        Haptic.light()
                        onboarding.previousStep()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.pawTextPrimary)
                            .padding(12)
                            .background(Color.pawCard)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)

                Spacer()

                // Content
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient.pawPrimary)
                            .frame(width: 100, height: 100)

                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // Header
                    VStack(spacing: 12) {
                        Text("Stay in the Loop")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.pawTextPrimary)

                        Text("Never miss when your pet's video is ready")
                            .font(.subheadline)
                            .foregroundColor(.pawTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Benefits
                    VStack(spacing: 16) {
                        ForEach(benefits, id: \.0) { icon, title, description in
                            HStack(spacing: 16) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(.pawSecondary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.pawTextPrimary)

                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.pawTextSecondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.pawCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .opacity(contentOpacity)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    Button {
                        requestNotifications()
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .tint(.pawBackground)
                            }
                            Text("Enable Notifications")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.pawBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.pawButton)
                        .clipShape(Capsule())
                    }
                    .disabled(isRequesting)

                    Button {
                        Haptic.light()
                        onboarding.notificationsRequested = true
                        onboarding.nextStep()
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(.pawTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1
            }
        }
    }

    private func requestNotifications() {
        isRequesting = true
        Haptic.medium()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                isRequesting = false
                onboarding.notificationsRequested = true
                Haptic.success()
                onboarding.nextStep()
            }
        }
    }
}

#Preview {
    NotificationsView()
        .environment(OnboardingManager())
}
