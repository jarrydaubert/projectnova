//
//  SplashView.swift
//  Project PawNova
//
//  Animated splash with video logo.
//  Plays intro once, then loops from 4s mark.
//  Auto-advances after animation completes.
//

import SwiftUI
import AVKit

struct SplashView: View {
    @Environment(OnboardingManager.self) private var onboarding

    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            // Aurora glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.pawPrimary.opacity(0.4),
                            Color.pawSecondary.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(glowPulse ? 1.1 : 0.9)
                .opacity(logoOpacity)

            VStack(spacing: 24) {
                // Animated video logo
                LoopingVideoPlayer(
                    videoName: "splash_logo",
                    loopFromTime: 4.0
                )
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .opacity(logoOpacity)

                // App name
                Text("PawNova")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.pawPrimary)
                    .opacity(textOpacity)

                // Tagline
                Text("AI Pet Videos")
                    .font(.subheadline)
                    .foregroundColor(.pawTextSecondary)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            animateSplash()
        }
    }

    private func animateSplash() {
        // Phase 1: Video appears
        withAnimation(.easeOut(duration: 0.5)) {
            logoOpacity = 1.0
        }

        // Phase 2: Text fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
        }

        // Phase 3: Gentle glow pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }

        // Phase 4: Advance to welcome after video plays once
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            onboarding.nextStep()
        }
    }
}

// MARK: - Looping Video Player

struct LoopingVideoPlayer: View {
    let videoName: String
    let loopFromTime: Double

    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?

    var body: some View {
        VideoPlayerView(player: player)
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player?.pause()
                player = nil
                playerLooper = nil
            }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("Video file not found: \(videoName).mp4")
            return
        }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true

        // Loop start time (after first playthrough)
        let loopStart = CMTime(seconds: loopFromTime, preferredTimescale: 600)

        // First play the full video, then set up looping
        player = queuePlayer
        player?.play()

        // After first playthrough, seek back to loop point
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak queuePlayer] _ in
            queuePlayer?.seek(to: loopStart) { _ in
                queuePlayer?.play()
            }
        }
    }
}

// MARK: - AVPlayer UIViewRepresentable

struct VideoPlayerView: UIViewRepresentable {
    let player: AVQueuePlayer?

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let playerView = uiView as? PlayerUIView else { return }
        playerView.player = player
    }
}

class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?

    var player: AVPlayer? {
        didSet {
            if let player = player {
                if playerLayer == nil {
                    let layer = AVPlayerLayer(player: player)
                    layer.videoGravity = .resizeAspectFill
                    layer.backgroundColor = UIColor.clear.cgColor
                    self.layer.addSublayer(layer)
                    playerLayer = layer
                } else {
                    playerLayer?.player = player
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

#Preview {
    SplashView()
        .environment(OnboardingManager())
}
