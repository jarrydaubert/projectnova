//
//  PawNovaLiveActivity.swift
//  PawNova Widget Extension
//
//  Live Activity for video generation progress.
//  Shows Dynamic Island and Lock Screen updates during AI video creation.
//

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Activity Attributes

/// Defines the static and dynamic content for the video generation Live Activity.
struct VideoGenerationAttributes: ActivityAttributes {
    /// Dynamic content that changes during the activity
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

    /// The AI model name
    var modelName: String

    /// Estimated duration in seconds
    var estimatedDuration: Int

    /// Credits used for this generation
    var creditsUsed: Int
}

// MARK: - Live Activity Widget

struct PawNovaLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VideoGenerationAttributes.self) { context in
            // Lock Screen view
            LiveActivityLockScreenView(
                state: context.state,
                modelName: context.attributes.modelName
            )
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(.purple)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.progressPercent)%")
                        .font(.headline.bold())
                        .foregroundColor(.purple)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Creating Video")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
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
                                    .frame(width: geo.size.width * context.state.progress)
                            }
                        }
                        .frame(height: 6)

                        Text(context.state.statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(.purple)
            } compactTrailing: {
                Text("\(context.state.progressPercent)%")
                    .font(.caption.bold())
            } minimal: {
                Image(systemName: context.state.isComplete ? "checkmark.circle.fill" : "pawprint.fill")
                    .foregroundStyle(context.state.isComplete ? .green : .purple)
            }
        }
    }
}

// MARK: - Lock Screen View

struct LiveActivityLockScreenView: View {
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
