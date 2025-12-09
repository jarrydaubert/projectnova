//
//  GenerationProgress.swift
//  Project PawNova
//
//  Real-time generation progress using AsyncSequence
//

import SwiftUI

// MARK: - Generation Status

enum GenerationStatus: Equatable {
    case idle
    case submitting
    case queued(position: Int?)
    case processing(progress: Double, stage: String)
    case downloading
    case completed(videoURL: String)
    case failed(error: String)

    var isInProgress: Bool {
        switch self {
        case .submitting, .queued, .processing, .downloading:
            return true
        default:
            return false
        }
    }

    var progressValue: Double {
        switch self {
        case .idle: return 0
        case .submitting: return 0.05
        case .queued: return 0.1
        case .processing(let progress, _): return 0.1 + (progress * 0.8)
        case .downloading: return 0.95
        case .completed: return 1.0
        case .failed: return 0
        }
    }

    var statusMessage: String {
        switch self {
        case .idle:
            return "Ready"
        case .submitting:
            return "Submitting request..."
        case .queued(let position):
            if let pos = position {
                return "In queue (position \(pos))..."
            }
            return "In queue..."
        case .processing(_, let stage):
            return stage.isEmpty ? "Generating video..." : stage
        case .downloading:
            return "Downloading video..."
        case .completed:
            return "Complete!"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }
}

// MARK: - Generation Progress Manager

@Observable
@MainActor
final class GenerationProgressManager {
    static let shared = GenerationProgressManager()

    var status: GenerationStatus = .idle
    var estimatedTimeRemaining: TimeInterval?

    private var continuation: AsyncStream<GenerationStatus>.Continuation?

    private init() {}

    /// Generate video with real-time progress updates
    func generateWithProgress(
        prompt: String,
        model: AIModel,
        aspectRatio: String,
        imageUrl: String? = nil
    ) -> AsyncThrowingStream<GenerationStatus, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Update status: Submitting
                    await self.updateStatus(.submitting)
                    continuation.yield(.submitting)

                    // Check network
                    try NetworkMonitor.shared.checkConnection()

                    // Sanitize prompt
                    let sanitizedPrompt = InputSanitizer.sanitizePrompt(prompt)

                    if InputSanitizer.containsBlockedContent(sanitizedPrompt) {
                        throw PawNovaError.contentBlocked
                    }

                    // If demo mode, simulate progress
                    if FalService.shared.demoMode {
                        try await self.simulateDemoProgress(continuation: continuation)
                        return
                    }

                    // Real API call with progress polling
                    let videoURL = try await self.generateWithPolling(
                        prompt: sanitizedPrompt,
                        model: model,
                        aspectRatio: aspectRatio,
                        imageUrl: imageUrl,
                        continuation: continuation
                    )

                    // Update status: Completed
                    await self.updateStatus(.completed(videoURL: videoURL))
                    continuation.yield(.completed(videoURL: videoURL))
                    continuation.finish()

                } catch {
                    let errorMessage = error.localizedDescription
                    await self.updateStatus(.failed(error: errorMessage))
                    continuation.yield(.failed(error: errorMessage))
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func updateStatus(_ newStatus: GenerationStatus) {
        self.status = newStatus
    }

    private func simulateDemoProgress(
        continuation: AsyncThrowingStream<GenerationStatus, Error>.Continuation
    ) async throws {
        // Simulate queued
        await updateStatus(.queued(position: 2))
        continuation.yield(.queued(position: 2))
        try await Task.sleep(nanoseconds: 500_000_000)

        await updateStatus(.queued(position: 1))
        continuation.yield(.queued(position: 1))
        try await Task.sleep(nanoseconds: 500_000_000)

        // Simulate processing stages
        let stages = [
            (0.1, "Analyzing prompt..."),
            (0.25, "Generating scene..."),
            (0.4, "Creating character..."),
            (0.55, "Adding details..."),
            (0.7, "Rendering video..."),
            (0.85, "Applying effects..."),
            (0.95, "Finalizing...")
        ]

        for (progress, stage) in stages {
            await updateStatus(.processing(progress: progress, stage: stage))
            continuation.yield(.processing(progress: progress, stage: stage))
            try await Task.sleep(nanoseconds: 400_000_000)
        }

        // Simulate download
        await updateStatus(.downloading)
        continuation.yield(.downloading)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Complete with mock URL
        let mockURL = FalService.shared.mockVideoURL(for: "demo")
        await updateStatus(.completed(videoURL: mockURL))
        continuation.yield(.completed(videoURL: mockURL))
        continuation.finish()
    }

    private func generateWithPolling(
        prompt: String,
        model: AIModel,
        aspectRatio: String,
        imageUrl: String?,
        continuation: AsyncThrowingStream<GenerationStatus, Error>.Continuation
    ) async throws -> String {
        // Submit job
        await updateStatus(.queued(position: nil))
        continuation.yield(.queued(position: nil))

        // Use the existing FalService but poll for status
        // This integrates with the existing implementation
        let videoURL = try await FalService.shared.generateVideo(
            prompt: prompt,
            model: model,
            aspectRatio: aspectRatio,
            imageUrl: imageUrl
        )

        return videoURL
    }

    /// Cancel current generation
    func cancel() {
        status = .idle
        continuation?.finish()
        continuation = nil
    }
}

// MARK: - Progress View Component

struct GenerationProgressView: View {
    let status: GenerationStatus
    var showEstimatedTime: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.pawCard, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: status.progressValue)
                    .stroke(
                        LinearGradient.pawPrimary,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: status.progressValue)

                // Center content
                VStack(spacing: 4) {
                    if status.isInProgress {
                        Image(systemName: "pawprint.fill")
                            .font(.title)
                            .foregroundStyle(LinearGradient.pawPrimary)
                            .symbolEffect(.pulse, options: .repeating)
                    } else if case .completed = status {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.pawSuccess)
                    } else if case .failed = status {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.pawError)
                    }

                    Text("\(Int(status.progressValue * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.pawTextSecondary)
                }
            }

            // Status message
            Text(status.statusMessage)
                .font(.subheadline)
                .foregroundColor(.pawTextPrimary)
                .multilineTextAlignment(.center)

            // Stage indicator
            if case .processing(_, let stage) = status, !stage.isEmpty {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.pawPrimary)
                    Text(stage)
                        .font(.caption)
                        .foregroundColor(.pawTextSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Inline Progress Bar

struct GenerationProgressBar: View {
    let status: GenerationStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pawCard)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.pawPrimary)
                        .frame(width: geo.size.width * status.progressValue)
                        .animation(.easeInOut(duration: 0.3), value: status.progressValue)
                }
            }
            .frame(height: 8)

            // Status text
            HStack {
                Text(status.statusMessage)
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)

                Spacer()

                Text("\(Int(status.progressValue * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.pawPrimary)
            }
        }
    }
}

#Preview("Progress View") {
    VStack(spacing: 20) {
        GenerationProgressView(status: .submitting)
        GenerationProgressView(status: .queued(position: 3))
        GenerationProgressView(status: .processing(progress: 0.45, stage: "Generating scene..."))
        GenerationProgressView(status: .completed(videoURL: ""))
    }
    .padding()
    .background(Color.pawBackground)
}

#Preview("Progress Bar") {
    VStack(spacing: 20) {
        GenerationProgressBar(status: .submitting)
        GenerationProgressBar(status: .processing(progress: 0.65, stage: "Rendering..."))
        GenerationProgressBar(status: .completed(videoURL: ""))
    }
    .padding()
    .background(Color.pawBackground)
}
