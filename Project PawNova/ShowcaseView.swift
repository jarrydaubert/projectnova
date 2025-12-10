//
//  ShowcaseView.swift
//  Project PawNova
//
//  Product showcase carousel demonstrating AI video capabilities.
//  Shows sample videos to convince users of the app's potential.
//

import SwiftUI
import AVKit

// MARK: - Showcase Item Model

struct ShowcaseItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let prompt: String
    let videoURL: URL?
    let thumbnailIcon: String
    let gradient: [Color]
}

// MARK: - Showcase View

struct ShowcaseView: View {
    @Environment(\.dismiss) private var dismiss
    var showDismissButton: Bool = true
    var onGetStarted: (() -> Void)?

    @State private var currentIndex = 0

    // Sample showcase items - replace with real AI-generated samples
    private let items: [ShowcaseItem] = [
        ShowcaseItem(
            title: "Magical Adventures",
            description: "Your pet exploring enchanted forests",
            prompt: "Golden retriever running through a magical forest with glowing fireflies at sunset",
            videoURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8"),
            thumbnailIcon: "sparkles",
            gradient: [.purple, .pink]
        ),
        ShowcaseItem(
            title: "Space Explorer",
            description: "Pets on intergalactic journeys",
            prompt: "Fluffy cat floating in a spaceship looking at stars through the window",
            videoURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"),
            thumbnailIcon: "moon.stars.fill",
            gradient: [.blue, .purple]
        ),
        ShowcaseItem(
            title: "Beach Paradise",
            description: "Sunny adventures by the ocean",
            prompt: "Happy corgi splashing in ocean waves on a tropical beach",
            videoURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"),
            thumbnailIcon: "sun.max.fill",
            gradient: [.orange, .yellow]
        ),
        ShowcaseItem(
            title: "Superhero Pets",
            description: "Your pet with amazing powers",
            prompt: "Brave German shepherd wearing a cape, flying over a city skyline",
            videoURL: nil,
            thumbnailIcon: "bolt.fill",
            gradient: [.red, .orange]
        )
    ]

    var body: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                if showDismissButton {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.pawTextSecondary)
                        }
                    }
                    .padding()
                }

                // Title
                VStack(spacing: 8) {
                    Text("See What's Possible")
                        .font(.title.bold())
                        .foregroundColor(.pawTextPrimary)

                    Text("AI-powered pet videos in seconds")
                        .font(.subheadline)
                        .foregroundColor(.pawTextSecondary)
                }
                .padding(.top, showDismissButton ? 0 : 40)
                .padding(.bottom, 24)

                // Carousel
                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        showcaseCard(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)

                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.pawPrimary : Color.pawTextSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.top, 16)

                Spacer()

                // CTA Button
                Button {
                    Haptic.medium()
                    if let action = onGetStarted {
                        action()
                    } else {
                        dismiss()
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline.bold())
                        .foregroundColor(.pawBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.pawButton)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
    }

    // MARK: - Showcase Card

    private func showcaseCard(_ item: ShowcaseItem) -> some View {
        VStack(spacing: 16) {
            // Video/Thumbnail Area
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: item.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 240)

                if let videoURL = item.videoURL {
                    // Video player
                    VideoPlayerCard(url: videoURL)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    // Placeholder with icon
                    VStack(spacing: 16) {
                        Image(systemName: item.thumbnailIcon)
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.9))

                        Text("Coming Soon")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Play badge
                if item.videoURL != nil {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                Text("AI Generated")
                                    .font(.caption2.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(12)
                        }
                        Spacer()
                    }
                }
            }

            // Title & Description
            VStack(spacing: 8) {
                Text(item.title)
                    .font(.title3.bold())
                    .foregroundColor(.pawTextPrimary)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.pawTextSecondary)
            }

            // Prompt Preview
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.pawPrimary)
                Text("\"\(item.prompt)\"")
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)
                    .lineLimit(2)
            }
            .padding()
            .background(Color.pawCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Video Player Card

struct VideoPlayerCard: View {
    let url: URL

    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .disabled(true) // Prevent user controls
            .onAppear {
                player = AVPlayer(url: url)
                player?.isMuted = true
                player?.play()

                // Loop video
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player?.currentItem,
                    queue: .main
                ) { _ in
                    player?.seek(to: .zero)
                    player?.play()
                }
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}

// MARK: - Previews

#Preview("Showcase") {
    ShowcaseView()
}

#Preview("Showcase Card") {
    ZStack {
        Color.pawBackground.ignoresSafeArea()
        ShowcaseView(showDismissButton: false)
    }
}
