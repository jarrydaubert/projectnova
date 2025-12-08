//
//  Project_PawNovaApp.swift
//  Project PawNova
//
//  Created by Jarryd Aubert on 04/12/2025.
//

import SwiftUI
import SwiftData

@main
struct Project_PawNovaApp: App {
    private let persistence = PersistenceController.shared
    @State private var onboardingManager: OnboardingManager
    @State private var storeService = StoreService.shared

    init() {
        let manager = OnboardingManager()

        // Handle UI test launch arguments
        #if DEBUG
        if CommandLine.arguments.contains("-resetOnboarding") {
            manager.reset()
        }
        if CommandLine.arguments.contains("-skipOnboarding") {
            manager.hasCompletedOnboarding = true
        }
        #endif

        _onboardingManager = State(initialValue: manager)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(onboardingManager)
                .environment(storeService)
        }
        .modelContainer(persistence.container)
    }
}

/// Root view that shows onboarding or main app based on state.
struct RootView: View {
    @Environment(OnboardingManager.self) private var onboarding

    var body: some View {
        Group {
            if onboarding.hasCompletedOnboarding || onboarding.currentStep == .complete {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingContainerView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboarding.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: onboarding.currentStep)
        .preferredColorScheme(.dark)
    }
}
