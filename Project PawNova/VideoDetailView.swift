//
//  VideoDetailView.swift
//  Project PawNova
//
//  Created by Jarryd Aubert on 04/12/2025.
//

import SwiftUI
import AVKit
import SwiftData

struct VideoDetailView: View {
    let video: PetVideo
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isFavorite: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Video Player
            if let url = video.generatedURL {
                VideoPlayer(player: player)
                    .frame(height: 300)
                    .onAppear {
                        player = AVPlayer(url: url)
                        player?.play()
                        isPlaying = true
                        Haptic.success()
                    }
                    .onDisappear {
                        player?.pause()
                    }
            } else {
                Rectangle()
                    .fill(Color.secondary)
                    .frame(height: 300)
                    .overlay {
                        Image(systemName: "video")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            // Details
            VStack(alignment: .leading, spacing: 12) {
                Text("Prompt")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(video.prompt)
                    .font(.body)
                    .multilineTextAlignment(.leading)

                if let photoURL = video.sourcePhotoURL {
                    Text("From Photo")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    AsyncImage(url: photoURL) { image in
                        image.resizable().scaledToFit().frame(maxHeight: 200).clipped()
                    } placeholder: {
                        ProgressView()
                    }
                }

                HStack(spacing: 24) {
                    Spacer()

                    Button {
                        if isPlaying {
                            player?.pause()
                            isPlaying = false
                        } else {
                            player?.play()
                            isPlaying = true
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            Text(isPlaying ? "Pause" : "Play")
                                .font(.caption2)
                        }
                        .foregroundStyle(.tint)
                    }

                    if let url = video.generatedURL {
                        SaveToPhotosButton(videoURL: url, style: .compact)
                    }

                    ShareLink(item: video.generatedURL ?? URL(string: "https://placeholder.com")!) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Share")
                                .font(.caption2)
                        }
                        .foregroundStyle(.tint)
                    }

                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle("Pet Adventure")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        duplicateVideo()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        deleteVideo()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            isFavorite = video.isFavorite
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        isFavorite.toggle()
        video.isFavorite = isFavorite
        try? modelContext.save()
        Haptic.success()
    }

    private func duplicateVideo() {
        let duplicate = PetVideo(
            prompt: video.prompt,
            generatedURL: video.generatedURL,
            timestamp: Date(),
            sourcePhotoURL: video.sourcePhotoURL
        )
        modelContext.insert(duplicate)
        try? modelContext.save()
        Haptic.success()
    }

    private func deleteVideo() {
        modelContext.delete(video)
        try? modelContext.save()
        Haptic.warning()
        dismiss()
    }
}

#Preview {
    VideoDetailView(video: PetVideo.samples().first!)
        .modelContainer(for: PetVideo.self, inMemory: true)
}
