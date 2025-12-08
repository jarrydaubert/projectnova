//
//  GeneratedVideoSheet.swift
//  Project PawNova
//
//  Full-screen presentation for newly generated videos
//

import SwiftUI
import AVKit

struct GeneratedVideoSheet: View {
    let videoURL: URL
    let prompt: String
    let onSave: () -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Video Player - Full screen with native controls
                VideoPlayer(player: player)
                    .ignoresSafeArea(edges: .top)

                // Bottom actions bar
                VStack(spacing: 16) {
                    // Prompt preview
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.pawSecondary)
                        Text(prompt)
                            .font(.caption)
                            .foregroundColor(.pawTextSecondary)
                            .lineLimit(2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Action buttons
                    HStack(spacing: 16) {
                        // Discard button
                        Button {
                            Haptic.warning()
                            onDiscard()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "xmark")
                                Text("Discard")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.pawTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.pawCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Share button
                        Button {
                            Haptic.light()
                            showShareSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.pawAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Save button
                        Button {
                            Haptic.success()
                            onSave()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.pawPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .background(Color.pawBackground)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            player = AVPlayer(url: videoURL)
            player?.play()
        }
        .onDisappear {
            player?.pause()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [videoURL])
        }
    }
}

// MARK: - Share Sheet (UIKit wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    GeneratedVideoSheet(
        videoURL: URL(string: "https://example.com/video.mp4")!,
        prompt: "A golden retriever running through a magical forest at sunset with butterflies",
        onSave: {},
        onDiscard: {}
    )
}
