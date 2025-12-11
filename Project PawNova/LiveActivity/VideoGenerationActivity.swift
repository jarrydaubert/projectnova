//
//  VideoGenerationActivity.swift
//  Project PawNova
//
//  Live Activity for video generation progress.
//  Shows Dynamic Island and Lock Screen updates during AI video creation.
//

import ActivityKit
import SwiftUI

// MARK: - Activity Attributes

/// Defines the static and dynamic content for the video generation Live Activity.
struct VideoGenerationAttributes: ActivityAttributes {
    /// Static content that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        /// Current progress (0.0 - 1.0)
        var progress: Double

        /// Current stage description (e.g., "Generating scene...")
        var stage: String

        /// Whether generation is complete
        var isComplete: Bool

        /// Optional video thumbnail URL (shown on completion)
        var thumbnailURL: String?

        /// Error message if failed
        var errorMessage: String?

        /// Helper for status text
        var statusText: String {
            if let error = errorMessage {
                return "Failed: \(error)"
            }
            if isComplete {
                return "Complete!"
            }
            return stage
        }

        /// Helper for progress percentage
        var progressPercent: Int {
            Int(progress * 100)
        }
    }

    /// The prompt being generated (static, set at start)
    var prompt: String

    /// The AI model being used
    var modelName: String

    /// Estimated duration in seconds
    var estimatedDuration: Int

    /// Credits being used
    var creditsUsed: Int
}

// MARK: - Live Activity Manager

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<VideoGenerationAttributes>?

    private init() {}

    /// Check if Live Activities are supported
    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Start a new Live Activity for video generation
    func startActivity(
        prompt: String,
        model: AIModel
    ) async throws -> Activity<VideoGenerationAttributes>? {
        guard isSupported else {
            DiagnosticsService.shared.warning("Live Activities not supported", category: "LiveActivity")
            return nil
        }

        // End any existing activity
        await endCurrentActivity()

        let attributes = VideoGenerationAttributes(
            prompt: String(prompt.prefix(50)) + (prompt.count > 50 ? "..." : ""),
            modelName: model.displayName,
            estimatedDuration: model.duration.isEmpty ? 8 : Int(model.duration.replacingOccurrences(of: "s", with: "")) ?? 8,
            creditsUsed: model.credits
        )

        let initialState = VideoGenerationAttributes.ContentState(
            progress: 0.0,
            stage: "Starting...",
            isComplete: false,
            thumbnailURL: nil,
            errorMessage: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil  // No push updates, we update locally
            )

            currentActivity = activity
            DiagnosticsService.shared.info("Live Activity started: \(activity.id)", category: "LiveActivity")
            return activity
        } catch {
            DiagnosticsService.shared.error("Failed to start Live Activity: \(error)", category: "LiveActivity")
            throw error
        }
    }

    /// Update the current Live Activity with new progress
    func updateProgress(_ progress: Double, stage: String) async {
        guard let activity = currentActivity else { return }

        let state = VideoGenerationAttributes.ContentState(
            progress: progress,
            stage: stage,
            isComplete: false,
            thumbnailURL: nil,
            errorMessage: nil
        )

        await activity.update(
            ActivityContent(state: state, staleDate: nil)
        )
    }

    /// Complete the Live Activity with success
    func completeActivity(thumbnailURL: String? = nil) async {
        guard let activity = currentActivity else { return }

        let finalState = VideoGenerationAttributes.ContentState(
            progress: 1.0,
            stage: "Complete!",
            isComplete: true,
            thumbnailURL: thumbnailURL,
            errorMessage: nil
        )

        // Keep visible for 5 seconds after completion
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .after(.now + 5)
        )

        currentActivity = nil
        DiagnosticsService.shared.info("Live Activity completed", category: "LiveActivity")
    }

    /// End the Live Activity with an error
    func failActivity(error: String) async {
        guard let activity = currentActivity else { return }

        let errorState = VideoGenerationAttributes.ContentState(
            progress: 0.0,
            stage: "Failed",
            isComplete: false,
            thumbnailURL: nil,
            errorMessage: error
        )

        await activity.end(
            ActivityContent(state: errorState, staleDate: nil),
            dismissalPolicy: .immediate
        )

        currentActivity = nil
        DiagnosticsService.shared.error("Live Activity failed: \(error)", category: "LiveActivity")
    }

    /// End the current activity without showing completion
    func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        let finalState = VideoGenerationAttributes.ContentState(
            progress: 0,
            stage: "Cancelled",
            isComplete: false,
            thumbnailURL: nil,
            errorMessage: nil
        )
        await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        currentActivity = nil
    }
}

// MARK: - Live Activity Views (for Widget Extension)
// NOTE: These views are designed to be used in the Widget Extension target.
// The Widget Extension should import this file and use these views in the
// ActivityConfiguration for the Live Activity.

/// Compact view for Dynamic Island (leading)
struct VideoGenerationCompactLeading: View {
    let state: VideoGenerationAttributes.ContentState

    var body: some View {
        Image(systemName: "pawprint.fill")
            .foregroundStyle(
                LinearGradient(
                    colors: [.purple, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

/// Compact view for Dynamic Island (trailing)
struct VideoGenerationCompactTrailing: View {
    let state: VideoGenerationAttributes.ContentState

    var body: some View {
        Text("\(state.progressPercent)%")
            .font(.caption.bold())
            .foregroundColor(.white)
    }
}

/// Minimal view for Dynamic Island (center, when minimal)
struct VideoGenerationMinimal: View {
    let state: VideoGenerationAttributes.ContentState

    var body: some View {
        Image(systemName: state.isComplete ? "checkmark.circle.fill" : "pawprint.fill")
            .foregroundStyle(state.isComplete ? .green : .purple)
    }
}

/// Expanded view for Dynamic Island
struct VideoGenerationExpanded: View {
    let state: VideoGenerationAttributes.ContentState
    let modelName: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(.purple)
                Text("Creating Video")
                    .font(.headline)
                Spacer()
                Text("\(state.progressPercent)%")
                    .font(.headline.bold())
                    .foregroundColor(.purple)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * state.progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text(state.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(modelName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

/// Lock Screen view
struct VideoGenerationLockScreen: View {
    let state: VideoGenerationAttributes.ContentState
    let modelName: String

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: state.isComplete ? "checkmark" : "pawprint.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("PawNova")
                    .font(.headline)

                Text(state.statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: state.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text("\(state.progressPercent)%")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding()
    }
}
