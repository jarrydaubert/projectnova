//
//  OnboardingManager.swift
//  Project PawNova
//
//  Manages onboarding flow (5 steps).
//  Persists completion status and subscription state to UserDefaults.
//

import SwiftUI

/// Onboarding steps - modern best practice flow
enum OnboardingStep: Int, CaseIterable {
    case splash = 0       // Animated logo (auto-advances)
    case welcome          // Welcome + Sign in (combined)
    case petName          // Pet personalization
    case notifications    // Push notification permissions
    case paywall          // Subscribe to continue
    case complete         // Done - show main app
}

/// Manages onboarding state and navigation.
@Observable
final class OnboardingManager {
    // MARK: - Persistence Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userName = "userName"
        static let petName = "petName"
        static let isSubscribed = "isSubscribed"
        static let notificationsRequested = "notificationsRequested"
    }

    // MARK: - State

    /// Current step in onboarding flow
    var currentStep: OnboardingStep = .splash

    /// Whether user has completed onboarding before
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    /// User's display name (from auth or manual entry)
    var userName: String {
        get { UserDefaults.standard.string(forKey: Keys.userName) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.userName) }
    }

    /// User's pet name
    var petName: String {
        get { UserDefaults.standard.string(forKey: Keys.petName) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.petName) }
    }

    /// Whether user is authenticated
    var isAuthenticated: Bool = false

    /// Whether user is subscribed (Pro) - persisted
    var isSubscribed: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.isSubscribed) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.isSubscribed) }
    }

    /// Whether notifications permission was requested
    var notificationsRequested: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notificationsRequested) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notificationsRequested) }
    }

    // MARK: - Navigation

    /// Advance to next onboarding step
    func nextStep() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextIndex
        }
    }

    /// Go back to previous step
    func previousStep() {
        guard let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1),
              prevIndex.rawValue >= OnboardingStep.welcome.rawValue else {
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevIndex
        }
    }

    /// Skip to specific step
    func goTo(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    /// Mark onboarding as complete
    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentStep = .complete
    }

    /// Reset onboarding (for testing)
    func reset() {
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: Keys.userName)
        UserDefaults.standard.removeObject(forKey: Keys.petName)
        UserDefaults.standard.removeObject(forKey: Keys.isSubscribed)
        UserDefaults.standard.removeObject(forKey: Keys.notificationsRequested)
        currentStep = .splash
        isAuthenticated = false
    }
}
