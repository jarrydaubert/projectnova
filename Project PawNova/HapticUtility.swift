//
//  HapticUtility.swift
//  Project PawNova
//
//  Centralized haptic feedback. Gracefully handles Simulator (no haptic hardware).
//

import UIKit

// MARK: - Haptic Feedback

@MainActor
enum Haptic {
    /// Check if device supports haptics (false on Simulator)
    private static var supportsHaptics: Bool = {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }()

    // MARK: - Notification Feedback

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func success() { notification(.success) }
    static func warning() { notification(.warning) }
    static func error() { notification(.error) }

    // MARK: - Impact Feedback

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func light() { impact(.light) }
    static func medium() { impact(.medium) }
    static func heavy() { impact(.heavy) }
    static func soft() { impact(.soft) }
    static func rigid() { impact(.rigid) }

    // MARK: - Selection Feedback

    static func selection() {
        guard supportsHaptics else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
