//
//  PetVideo.swift
//  Project PawNova
//
//  Created by Jarryd Aubert on 04/12/2025.
//

import Foundation
import SwiftData

/// A SwiftData model representing a generated pet video request.
/// Stores the user's prompt, an optional generated video URL, the creation timestamp, and optional source photo URL.
@Model
final class PetVideo {
    // Single #Index macro: Separate indexes for prompt (text searches) and timestamp (sorts/queries).
    // iOS 18+/Swift 6 only—combine all indexes here.
    #Index<PetVideo>([\.prompt], [\.timestamp])

    /// The user's text prompt that describes the desired video.
    var prompt: String

    /// The URL to the generated video, if available.
    var generatedURL: URL?

    /// Creation date used for sorting and history display.
    var timestamp: Date  // 'var' for Swift 6 @Model compatibility (set in init, never mutated)

    /// The source photo URL if generated from uploaded pet photo (optional for text-only path).
    var sourcePhotoURL: URL?

    /// Whether the user has marked this video as a favorite.
    var isFavorite: Bool = false

    // MARK: - Generation Metadata

    /// The AI model used for generation (e.g., "veo3Fast", "kling25")
    var modelUsed: String?

    /// The aspect ratio used (e.g., "16:9", "9:16", "1:1")
    var aspectRatio: String?

    /// Video duration in seconds
    var duration: Int?

    /// Credits spent on this generation
    var creditsSpent: Int?

    /// A short preview of the prompt, truncated to 30 characters with an ellipsis when needed.
    var promptPreview: String {
        let s = prompt
        return s.count > 30 ? String(s.prefix(30)) + "…" : s
    }

    /// Indicates whether a video URL has been generated for this record.
    var isGenerated: Bool { generatedURL != nil }

    /// Display name for the model used
    var modelDisplayName: String {
        guard let model = modelUsed else { return "Unknown" }
        switch model {
        case "veo3Fast": return "Veo 3 Fast"
        case "veo3Standard": return "Veo 3 Pro"
        case "kling25": return "Kling 2.5"
        case "hailuo02": return "Hailuo AI"
        default: return model
        }
    }

    init(
        prompt: String,
        generatedURL: URL? = nil,
        timestamp: Date = Date(),
        sourcePhotoURL: URL? = nil,
        modelUsed: String? = nil,
        aspectRatio: String? = nil,
        duration: Int? = nil,
        creditsSpent: Int? = nil
    ) {
        self.prompt = prompt
        self.generatedURL = generatedURL
        self.timestamp = timestamp
        self.sourcePhotoURL = sourcePhotoURL
        self.modelUsed = modelUsed
        self.aspectRatio = aspectRatio
        self.duration = duration
        self.creditsSpent = creditsSpent
    }

    #if DEBUG
        /// Sample records for SwiftUI previews and tests.
        static func samples() -> [PetVideo] {
            [
                PetVideo(prompt: "My cat as a space explorer"),
                PetVideo(prompt: "Golden retriever surfing a wave"),
                PetVideo(prompt: "Parrot piloting a tiny drone")
            ]
        }
    #endif
}
