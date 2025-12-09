//
//  Tips.swift
//  Project PawNova
//
//  TipKit tips for contextual guidance
//

import SwiftUI
import TipKit

// MARK: - Prompt Tips

/// Tip shown on the prompt input field
struct PromptTip: Tip {
    var title: Text {
        Text("Write Descriptive Prompts")
    }

    var message: Text? {
        Text("Include your pet type, action, setting, and mood for best results. Example: \"Golden retriever running through autumn leaves at sunset\"")
    }

    var image: Image? {
        Image(systemName: "sparkles")
    }
}

/// Tip for adding pet breed
struct BreedTip: Tip {
    var title: Text {
        Text("Add Your Pet's Breed")
    }

    var message: Text? {
        Text("Mentioning the specific breed helps the AI create more accurate videos.")
    }

    var image: Image? {
        Image(systemName: "pawprint.fill")
    }

    // Show after 2 video generations without breed mentioned
    @Parameter
    static var videosWithoutBreed: Int = 0

    var rules: [Rule] {
        #Rule(Self.$videosWithoutBreed) { $0 >= 2 }
    }
}

// MARK: - Model Selection Tips

/// Tip explaining model differences
struct ModelSelectionTip: Tip {
    var title: Text {
        Text("Choose the Right Model")
    }

    var message: Text? {
        Text("Veo 3 Fast is great for quick previews. Kling 2.5 offers higher quality for final videos.")
    }

    var image: Image? {
        Image(systemName: "wand.and.stars")
    }

    // Only show once
    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

// MARK: - Photo Tips

/// Tip for photo-to-video mode
struct PhotoInputTip: Tip {
    var title: Text {
        Text("Best Photo Tips")
    }

    var message: Text? {
        Text("Use clear, well-lit photos with your pet facing the camera. Close-ups work better than wide shots.")
    }

    var image: Image? {
        Image(systemName: "photo.fill")
    }

    // Show when user first enters photo mode
    @Parameter
    static var hasUsedPhotoMode: Bool = false

    var rules: [Rule] {
        #Rule(Self.$hasUsedPhotoMode) { !$0 }
    }
}

// MARK: - Library Tips

/// Tip for favoriting videos
struct FavoriteTip: Tip {
    var title: Text {
        Text("Save Your Favorites")
    }

    var message: Text? {
        Text("Tap the star to favorite videos. Find them quickly in the Favorites filter.")
    }

    var image: Image? {
        Image(systemName: "star.fill")
    }

    // Show after user has 3+ videos
    @Parameter
    static var videoCount: Int = 0

    var rules: [Rule] {
        #Rule(Self.$videoCount) { $0 >= 3 }
    }
}

/// Tip for sharing videos
struct ShareTip: Tip {
    var title: Text {
        Text("Share Your Creations")
    }

    var message: Text? {
        Text("Save videos to Photos or share directly to TikTok, Instagram, and more!")
    }

    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }

    // Show after first video generation
    @Parameter
    static var hasGeneratedVideo: Bool = false

    var rules: [Rule] {
        #Rule(Self.$hasGeneratedVideo) { $0 }
    }
}

// MARK: - Credit Tips

/// Tip about credits
struct CreditTip: Tip {
    var title: Text {
        Text("Credits Explained")
    }

    var message: Text? {
        Text("Each video uses credits based on the AI model. Check the cost before generating.")
    }

    var image: Image? {
        Image(systemName: "sparkles")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

/// Tip when credits are low
struct LowCreditsTip: Tip {
    var title: Text {
        Text("Running Low on Credits")
    }

    var message: Text? {
        Text("Get more credits or subscribe to PawNova Pro for unlimited generation.")
    }

    var image: Image? {
        Image(systemName: "exclamationmark.triangle.fill")
    }

    @Parameter
    static var credits: Int = 5000

    var rules: [Rule] {
        #Rule(Self.$credits) { $0 < 500 && $0 > 0 }
    }
}

// MARK: - Settings Tips

/// Tip about notifications
struct NotificationTip: Tip {
    var title: Text {
        Text("Enable Notifications")
    }

    var message: Text? {
        Text("Get notified when your videos are ready, even when the app is closed.")
    }

    var image: Image? {
        Image(systemName: "bell.fill")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

// MARK: - TipKit Configuration

enum TipConfiguration {
    static func configure() {
        do {
            // Configure tips for the app
            #if DEBUG
            try Tips.configure([.displayFrequency(.immediate)])
            #else
            try Tips.configure([.displayFrequency(.hourly)])
            #endif
        } catch {
            ErrorLogger.shared.log(error, context: "TipKit")
        }
    }

    /// Reset all tips (useful for testing)
    static func resetAllTips() {
        #if DEBUG
        try? Tips.resetDatastore()
        #endif
    }

    /// Update tip parameters based on app state
    @MainActor
    static func updateTipState(videoCount: Int, credits: Int, hasGeneratedVideo: Bool) {
        FavoriteTip.videoCount = videoCount
        LowCreditsTip.credits = credits
        ShareTip.hasGeneratedVideo = hasGeneratedVideo
    }
}

// MARK: - Tip View Helpers

extension View {
    /// Adds a popover tip to any view
    func tipPopover(_ tip: some Tip, arrowEdge: Edge = .top) -> some View {
        self.popoverTip(tip, arrowEdge: arrowEdge)
    }

    /// Adds an inline tip below the view
    func tipInline(_ tip: some Tip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            self
            TipView(tip)
        }
    }
}
