//
//  AppGroupData.swift
//  Project PawNova
//
//  Shared data container for App Group communication between main app and widgets.
//  App Group ID: group.com.pawnova.shared
//

import Foundation
import SwiftData

// MARK: - App Group Configuration

enum AppGroupConfig {
    /// The App Group identifier for sharing data between app and widgets
    static let identifier = "group.com.pawnova.shared"

    /// URL to the shared container directory
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// URL to the shared SwiftData store
    static var sharedStoreURL: URL? {
        containerURL?.appendingPathComponent("PawNova.store")
    }
}

// MARK: - Shared Video Data (for Widget)

/// Lightweight video data structure for widget communication
/// Avoids complex SwiftData dependencies in widget extension
struct SharedVideoData: Codable, Identifiable {
    let id: String
    let prompt: String
    let thumbnailURL: String?
    let generatedURL: String?
    let timestamp: Date
    let isFavorite: Bool
    let modelUsed: String?

    init(from video: PetVideo) {
        // Create a unique ID from timestamp and prompt hash since PetVideo uses SwiftData's implicit ID
        let hashValue = abs(video.prompt.hashValue)
        self.id = "\(Int(video.timestamp.timeIntervalSince1970))_\(hashValue)"
        self.prompt = video.prompt
        self.thumbnailURL = video.generatedURL?.absoluteString
        self.generatedURL = video.generatedURL?.absoluteString
        self.timestamp = video.timestamp
        self.isFavorite = video.isFavorite
        self.modelUsed = video.modelUsed
    }
}

// MARK: - Shared Data Manager

/// Manages shared data between main app and widget extension
@MainActor
final class SharedDataManager {
    static let shared = SharedDataManager()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var sharedVideosURL: URL? {
        AppGroupConfig.containerURL?.appendingPathComponent("recent_videos.json")
    }

    private init() {}

    /// Write recent videos to shared container for widget access
    func updateRecentVideos(_ videos: [PetVideo]) {
        guard let url = sharedVideosURL else {
            DiagnosticsService.shared.warning("App Group container not available", category: "SharedData")
            return
        }

        do {
            // Convert to lightweight shared format
            let sharedVideos = videos.prefix(10).map { SharedVideoData(from: $0) }
            let data = try encoder.encode(sharedVideos)
            try data.write(to: url, options: .atomic)

            DiagnosticsService.shared.info("Updated \(sharedVideos.count) videos in shared container", category: "SharedData")
        } catch {
            DiagnosticsService.shared.error("Failed to write shared videos: \(error)", category: "SharedData")
        }
    }

    /// Read recent videos from shared container (called by widget)
    func readRecentVideos() -> [SharedVideoData] {
        guard let url = sharedVideosURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([SharedVideoData].self, from: data)
        } catch {
            DiagnosticsService.shared.error("Failed to read shared videos: \(error)", category: "SharedData")
            return []
        }
    }

    /// Clear all shared data
    func clearSharedData() {
        guard let url = sharedVideosURL else { return }

        try? FileManager.default.removeItem(at: url)
        DiagnosticsService.shared.info("Cleared shared data", category: "SharedData")
    }
}

// MARK: - Widget Reload Helper

import WidgetKit

extension SharedDataManager {
    /// Notify widgets to reload their timelines after data changes
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        DiagnosticsService.shared.info("Requested widget timeline reload", category: "SharedData")
    }

    /// Update shared data and reload widgets
    func syncAndReloadWidgets(_ videos: [PetVideo]) {
        updateRecentVideos(videos)
        reloadWidgets()
    }
}
