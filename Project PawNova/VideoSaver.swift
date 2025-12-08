//
//  VideoSaver.swift
//  Project PawNova
//
//  Utility for downloading and saving videos to Photos library
//

import Foundation
import Photos
import UIKit

enum VideoSaverError: LocalizedError {
    case photoLibraryAccessDenied
    case downloadFailed
    case saveFailed
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo library access denied. Please enable access in Settings."
        case .downloadFailed:
            return "Failed to download video. Please check your internet connection."
        case .saveFailed:
            return "Failed to save video to Photos."
        case .invalidURL:
            return "Invalid video URL."
        }
    }
}

@MainActor
@Observable
class VideoSaver {
    static let shared = VideoSaver()

    var isSaving = false
    var progress: Double = 0

    private init() {}

    /// Request photo library permission
    func requestPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// Save video from URL to Photos library
    func saveToPhotos(from url: URL) async throws {
        // Request permission first
        guard await requestPermission() else {
            throw VideoSaverError.photoLibraryAccessDenied
        }

        isSaving = true
        progress = 0

        defer {
            isSaving = false
            progress = 0
        }

        // Download video to temporary location
        let tempURL = try await downloadVideo(from: url)

        // Save to Photos library
        try await saveVideoToLibrary(tempURL: tempURL)

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
    }

    private func downloadVideo(from url: URL) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: url, delegate: nil)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VideoSaverError.downloadFailed
        }

        // Move to a location we control
        let documentsPath = FileManager.default.temporaryDirectory
        let destinationURL = documentsPath.appendingPathComponent("pawnova_temp_\(UUID().uuidString).mp4")

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        return destinationURL
    }

    private func saveVideoToLibrary(tempURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? VideoSaverError.saveFailed)
                }
            }
        }
    }
}

// MARK: - SwiftUI View Modifier for Save to Photos

import SwiftUI

struct SaveToPhotosButton: View {
    let videoURL: URL
    let style: ButtonDisplayStyle

    @State private var saver = VideoSaver.shared
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum ButtonDisplayStyle {
        case compact
        case full
    }

    var body: some View {
        Button {
            Task {
                await saveVideo()
            }
        } label: {
            if saver.isSaving {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(style == .full ? .white : .pawPrimary)
                    Text("Saving...")
                }
            } else if showSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Saved!")
                }
                .foregroundColor(.pawSuccess)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.on.square")
                    Text("Save to Photos")
                }
            }
        }
        .disabled(saver.isSaving)
        .modifier(ButtonStyleModifier(style: style))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
            if errorMessage.contains("Settings") {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func saveVideo() async {
        Haptic.medium()

        do {
            try await VideoSaver.shared.saveToPhotos(from: videoURL)
            Haptic.success()
            showSuccess = true

            // Reset after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSuccess = false
        } catch {
            Haptic.error()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct ButtonStyleModifier: ViewModifier {
    let style: SaveToPhotosButton.ButtonDisplayStyle

    func body(content: Content) -> some View {
        switch style {
        case .compact:
            content
                .font(.subheadline.bold())
                .foregroundColor(.pawPrimary)
        case .full:
            content
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.pawSuccess)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
