//
//  PawNova.swift
//  PawNova Widget Extension
//
//  Interactive home screen widget showing recent videos.
//  Supports small and medium sizes.
//

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Widget Entry

struct PawNovaWidgetEntry: TimelineEntry {
    let date: Date
    let recentVideos: [WidgetVideo]
    let totalCount: Int
}

/// Lightweight video model for widget
struct WidgetVideo: Identifiable {
    let id: String
    let prompt: String
    let thumbnailURL: URL?
    let timestamp: Date

    var promptPreview: String {
        prompt.count > 25 ? String(prompt.prefix(25)) + "..." : prompt
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Shared Data Reader

/// Reads shared video data from App Group container
struct SharedVideoDataReader {
    static let appGroupID = "group.com.pawnova.shared"

    static func readRecentVideos() -> [WidgetVideo] {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            return []
        }

        let fileURL = containerURL.appendingPathComponent("recent_videos.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let sharedVideos = try decoder.decode([SharedVideoJSON].self, from: data)
            return sharedVideos.map { video in
                WidgetVideo(
                    id: video.id,
                    prompt: video.prompt,
                    thumbnailURL: video.thumbnailURL.flatMap { URL(string: $0) },
                    timestamp: video.timestamp
                )
            }
        } catch {
            return []
        }
    }
}

/// JSON structure matching SharedVideoData from main app
private struct SharedVideoJSON: Codable {
    let id: String
    let prompt: String
    let thumbnailURL: String?
    let generatedURL: String?
    let timestamp: Date
    let isFavorite: Bool
    let modelUsed: String?
}

// MARK: - Timeline Provider

struct PawNovaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PawNovaWidgetEntry {
        PawNovaWidgetEntry(
            date: Date(),
            recentVideos: [
                WidgetVideo(id: "1", prompt: "Cat exploring space", thumbnailURL: nil, timestamp: Date())
            ],
            totalCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PawNovaWidgetEntry) -> Void) {
        let entry = PawNovaWidgetEntry(
            date: Date(),
            recentVideos: [
                WidgetVideo(id: "1", prompt: "My cat as a superhero", thumbnailURL: nil, timestamp: Date().addingTimeInterval(-3600)),
                WidgetVideo(id: "2", prompt: "Dog playing on beach", thumbnailURL: nil, timestamp: Date().addingTimeInterval(-7200))
            ],
            totalCount: 12
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PawNovaWidgetEntry>) -> Void) {
        let videos = SharedVideoDataReader.readRecentVideos()
        let entry = PawNovaWidgetEntry(
            date: Date(),
            recentVideos: videos,
            totalCount: videos.count
        )

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct PawNovaWidgetSmallView: View {
    let entry: PawNovaWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#0F0F1A"), Color(hex: "#1A1A2E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#8B5CF6"), Color(hex: "#34D399")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Spacer()
                    Text("\(entry.totalCount)")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if let video = entry.recentVideos.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.promptPreview)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(video.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#34D399"), Color(hex: "#8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Create Video")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
}

struct PawNovaWidgetMediumView: View {
    let entry: PawNovaWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#0F0F1A"), Color(hex: "#1A1A2E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#8B5CF6"), Color(hex: "#34D399")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("PawNova")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    if entry.recentVideos.isEmpty {
                        Spacer()
                        Text("No videos yet")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    } else {
                        ForEach(entry.recentVideos.prefix(2)) { video in
                            HStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#8B5CF6").opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "play.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(video.promptPreview)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(video.timeAgo)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }

                    Spacer()
                }

                Spacer()

                VStack {
                    Spacer()
                    if let createURL = URL(string: "pawnova://create") {
                        Link(destination: createURL) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "#34D399"), Color(hex: "#8B5CF6")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                Text("Create")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            .frame(width: 70, height: 70)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    Spacer()
                }
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration

struct PawNovaWidget: Widget {
    let kind: String = "PawNovaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PawNovaWidgetProvider()) { entry in
            PawNovaWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("PawNova")
        .description("See your recent AI pet videos and create new ones.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PawNovaWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PawNovaWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            PawNovaWidgetSmallView(entry: entry)
        case .systemMedium:
            PawNovaWidgetMediumView(entry: entry)
        default:
            PawNovaWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Previews

#Preview("Small Widget", as: .systemSmall) {
    PawNovaWidget()
} timeline: {
    PawNovaWidgetEntry(
        date: Date(),
        recentVideos: [
            WidgetVideo(id: "1", prompt: "My cat exploring the galaxy", thumbnailURL: nil, timestamp: Date().addingTimeInterval(-3600))
        ],
        totalCount: 5
    )
}

#Preview("Medium Widget", as: .systemMedium) {
    PawNovaWidget()
} timeline: {
    PawNovaWidgetEntry(
        date: Date(),
        recentVideos: [
            WidgetVideo(id: "1", prompt: "Cat as a superhero", thumbnailURL: nil, timestamp: Date().addingTimeInterval(-3600)),
            WidgetVideo(id: "2", prompt: "Dog surfing waves", thumbnailURL: nil, timestamp: Date().addingTimeInterval(-7200))
        ],
        totalCount: 12
    )
}

#Preview("Empty Widget", as: .systemSmall) {
    PawNovaWidget()
} timeline: {
    PawNovaWidgetEntry(date: Date(), recentVideos: [], totalCount: 0)
}
