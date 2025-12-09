import Foundation
import os

// MARK: - Logging

private let logger = Logger(subsystem: "com.pawnova.PawNova", category: "FalService")

// MARK: - AI Model Selection

/// Available AI video generation models on fal.ai
/// Pricing based on fal.ai rates with markup for profitability
enum AIModel: String, CaseIterable, Identifiable {
    case veo3Fast = "fal-ai/veo3/fast"
    case veo3Standard = "fal-ai/veo3"
    case kling25 = "fal-ai/kling-video/v2.5/pro/text-to-video"
    case hailuo02 = "fal-ai/minimax/hailuo-02/pro/text-to-video"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .veo3Fast: return "Veo 3 Fast"
        case .veo3Standard: return "Veo 3 Pro"
        case .kling25: return "Kling 2.5"
        case .hailuo02: return "Hailuo AI"
        }
    }

    var provider: String {
        switch self {
        case .veo3Fast, .veo3Standard: return "Google"
        case .kling25: return "Kuaishou"
        case .hailuo02: return "MiniMax"
        }
    }

    /// Credit cost per generation (markup ~4x on API cost)
    var credits: Int {
        switch self {
        case .veo3Fast: return 800      // ~$0.80 API cost → 800 credits
        case .veo3Standard: return 2000 // ~$2.00 API cost → 2000 credits
        case .kling25: return 600       // ~$0.56 API cost → 600 credits
        case .hailuo02: return 500      // ~$0.48 API cost → 500 credits
        }
    }

    var duration: String {
        switch self {
        case .veo3Fast, .veo3Standard: return "8s"
        case .kling25: return "5s"
        case .hailuo02: return "6s"
        }
    }

    var description: String {
        switch self {
        case .veo3Fast: return "Fast generation, great quality"
        case .veo3Standard: return "Premium quality with audio"
        case .kling25: return "Best for action & motion"
        case .hailuo02: return "Best for faces & expressions"
        }
    }

    /// Whether this model supports audio generation
    var supportsAudio: Bool {
        switch self {
        case .veo3Fast, .veo3Standard: return true
        case .kling25, .hailuo02: return false
        }
    }
}

// MARK: - Models

struct TextToImageRequest: Codable {
    let prompt: String
    let imageSize: String = "landscape_16_9"
    let numInferenceSteps: Int = 4
    let numImages: Int = 1

    enum CodingKeys: String, CodingKey {
        case prompt
        case imageSize = "image_size"
        case numInferenceSteps = "num_inference_steps"
        case numImages = "num_images"
    }
}

struct Veo3Request: Codable {
    let prompt: String
    let imageUrl: String?
    let duration: Int = 8
    let aspectRatio: String = "16:9"
    let audio: Bool = true

    enum CodingKeys: String, CodingKey {
        case prompt
        case imageUrl = "image_url"
        case duration
        case aspectRatio = "aspect_ratio"
        case audio
    }
}

struct Kling25Request: Codable {
    let prompt: String
    let imageUrl: String?
    let duration: Int = 5
    let aspectRatio: String = "16:9"

    enum CodingKeys: String, CodingKey {
        case prompt
        case imageUrl = "image_url"
        case duration
        case aspectRatio = "aspect_ratio"
    }
}

struct Hailuo02Request: Codable {
    let prompt: String
    let imageUrl: String?
    let duration: String = "6"
    let resolution: String = "1080p"

    enum CodingKeys: String, CodingKey {
        case prompt
        case imageUrl = "image_url"
        case duration
        case resolution
    }
}

struct TextToImageResponse: Codable {
    let images: [ImageOutput]

    struct ImageOutput: Codable {
        let url: String
        let width: Int
        let height: Int
    }
}

struct ImageToVideoRequest: Codable {
    let imageUrl: String
    let prompt: String
    let duration: String = "6" // "6" or "10" seconds

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case prompt
        case duration
    }
}

struct ImageToVideoResponse: Codable {
    let video: VideoOutput

    struct VideoOutput: Codable {
        let url: String
    }
}

struct FalResponse<T: Codable>: Codable {
    let requestId: String?
    let status: String?
    let data: T?

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case status
        case data
    }
}

// MARK: - Service

/// Main service for fal.ai API integration.
/// Thread-safe via @MainActor isolation. URLSession injectable for testing.
@MainActor
final class FalService {
    static let shared = FalService()

    private let baseURL = "https://queue.fal.run"
    private let session: URLSession

    // MARK: - Demo Mode (Free Testing)
    /// Set to true to use mock generations (no API calls, $0 cost)
    /// Set to false to use real fal.ai API (requires credits)
    var demoMode: Bool = true  // Default to demo for testing

    // TODO: Move to server-side proxy for production
    // Get your key at: https://fal.ai/dashboard/keys
    private var apiKey: String {
        // For now, we'll read from environment or return empty
        // You should set this via Xcode scheme environment variables
        ProcessInfo.processInfo.environment["FAL_KEY"] ?? ""
    }

    /// Creates a FalService instance.
    /// - Parameter session: URLSession to use for network requests. Defaults to `.shared`.
    ///                      Pass a custom session for testing with MockURLProtocol.
    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - AI Prompt Enhancement

    /// Enhances a user's prompt with cinematic details and professional phrasing
    /// Only use this if the user has AI enhance enabled
    func enhancePrompt(_ prompt: String) -> String {
        // Already enhanced or very detailed? Return as-is
        if prompt.lowercased().contains("cinematic") ||
           prompt.lowercased().contains("professional") ||
           prompt.count > 150 {
            return prompt
        }

        // Add cinematic enhancement based on content
        let baseEnhancement = "Cinematic video: \(prompt)."
        let visualEnhancement = " High-quality, professional lighting, smooth camera movement."
        let petEnhancement = " Adorable and engaging pet performance, vibrant colors, heartwarming atmosphere."

        // Check if it's pet-related
        let lowerPrompt = prompt.lowercased()
        let isPetRelated = lowerPrompt.contains("cat") || lowerPrompt.contains("dog") ||
                          lowerPrompt.contains("pet") || lowerPrompt.contains("puppy") ||
                          lowerPrompt.contains("kitten") || lowerPrompt.contains("animal")

        if isPetRelated {
            return baseEnhancement + visualEnhancement + petEnhancement
        } else {
            return baseEnhancement + visualEnhancement
        }
    }

    // MARK: - Direct Video Generation (Veo 3 / Sora 2)

    func generateVideo(prompt: String, model: AIModel, aspectRatio: String = "16:9", imageUrl: String? = nil) async throws -> String {
        // DEMO MODE: Return mock video instantly
        if demoMode {
            logger.info("🎭 DEMO MODE: Generating mock video with \(model.displayName)")
            logger.debug("🎭 Prompt: '\(prompt)'")
            if let imageUrl = imageUrl {
                logger.debug("🎭 Image URL: \(imageUrl)")
            }
            // Simulate API delay (longer for video)
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            let mockURL = mockVideoURL(for: prompt)
            logger.info("🎭 DEMO MODE: Returning mock video: \(mockURL)")
            return mockURL
        }

        // REAL API MODE
        let endpoint = model.rawValue

        // Check API key
        guard !apiKey.isEmpty else {
            logger.error("❌ FAL API Key is missing! Set FAL_KEY environment variable in Xcode scheme.")
            throw FalServiceError.missingAPIKey
        }

        logger.info("✅ Using \(model.displayName) (\(model.provider))")
        logger.info("✅ Cost: \(model.credits) credits, Duration: \(model.duration)")

        // Submit job
        let submitURL = URL(string: "\(baseURL)/\(endpoint)")!
        var submitRequest = URLRequest(url: submitURL)
        submitRequest.httpMethod = "POST"
        submitRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        submitRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any]
        switch model {
        case .veo3Fast, .veo3Standard:
            requestBody = [
                "prompt": prompt,
                "image_url": imageUrl as Any,
                "duration": 8,
                "aspect_ratio": aspectRatio,
                "audio": model.supportsAudio
            ]
        case .kling25:
            requestBody = [
                "prompt": prompt,
                "image_url": imageUrl as Any,
                "duration": 5,
                "aspect_ratio": aspectRatio
            ]
        case .hailuo02:
            requestBody = [
                "prompt": prompt,
                "image_url": imageUrl as Any,
                "duration": "6",
                "resolution": "1080p"
            ]
        }

        submitRequest.httpBody = try JSONSerialization.data(withJSONObject: ["input": requestBody])

        let (submitData, submitResponse) = try await session.data(for: submitRequest)

        guard let httpResponse = submitResponse as? HTTPURLResponse else {
            throw FalServiceError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorString = String(data: submitData, encoding: .utf8) ?? "Unable to decode error"
            logger.error("❌ FAL API Error (Status \(httpResponse.statusCode)): \(errorString)")
            throw FalServiceError.invalidResponse
        }

        let submitResult = try JSONDecoder().decode(SubmitResponse.self, from: submitData)
        return try await pollForVideoResult(requestId: submitResult.requestId, endpoint: endpoint)
    }

    // MARK: - Legacy Text to Image (Flux Schnell) - Deprecated, use generateVideo instead

    func generateImage(prompt: String) async throws -> String {
        // DEMO MODE: Return mock image instantly
        if demoMode {
            logger.info("🎭 DEMO MODE: Generating mock image for prompt: '\(prompt)'")
            // Simulate API delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            let mockURL = mockImageURL(for: prompt)
            logger.info("🎭 DEMO MODE: Returning mock URL: \(mockURL)")
            return mockURL
        }

        // REAL API MODE
        let endpoint = "fal-ai/flux/schnell"
        let request = TextToImageRequest(prompt: prompt)

        // Check API key
        guard !apiKey.isEmpty else {
            logger.error("❌ FAL API Key is missing! Set FAL_KEY environment variable in Xcode scheme.")
            throw FalServiceError.missingAPIKey
        }

        logger.info("✅ Using API key: \(String(self.apiKey.prefix(8)))...")

        // Submit job
        let submitURL = URL(string: "\(baseURL)/\(endpoint)")!
        var submitRequest = URLRequest(url: submitURL)
        submitRequest.httpMethod = "POST"
        submitRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        submitRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["input": request]
        submitRequest.httpBody = try JSONEncoder().encode(requestBody)

        let (submitData, submitResponse) = try await session.data(for: submitRequest)

        guard let httpResponse = submitResponse as? HTTPURLResponse else {
            throw FalServiceError.invalidResponse
        }

        // Log error response for debugging
        if httpResponse.statusCode != 200 {
            let errorString = String(data: submitData, encoding: .utf8) ?? "Unable to decode error"
            logger.error("❌ FAL API Error (Status \(httpResponse.statusCode)): \(errorString)")
            throw FalServiceError.invalidResponse
        }

        // Parse request ID
        do {
            let submitResult = try JSONDecoder().decode(SubmitResponse.self, from: submitData)

            // Poll for result
            return try await pollForResult(requestId: submitResult.requestId, endpoint: endpoint)
        } catch {
            let responseString = String(data: submitData, encoding: .utf8) ?? "Unable to decode response"
            logger.error("❌ JSON Decode Error: \(error)")
            logger.debug("📄 Response: \(responseString)")
            throw FalServiceError.invalidResponse
        }
    }

    // MARK: - Image to Video (MiniMax Hailuo) - DEPRECATED

    func generateVideoFromImage(imageUrl: String, prompt: String) async throws -> String {
        let endpoint = "fal-ai/minimax/hailuo-02/standard/image-to-video"
        let request = ImageToVideoRequest(imageUrl: imageUrl, prompt: prompt)

        // Submit job
        let submitURL = URL(string: "\(baseURL)/\(endpoint)")!
        var submitRequest = URLRequest(url: submitURL)
        submitRequest.httpMethod = "POST"
        submitRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        submitRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["input": request]
        submitRequest.httpBody = try JSONEncoder().encode(requestBody)

        let (submitData, submitResponse) = try await session.data(for: submitRequest)

        guard let httpResponse = submitResponse as? HTTPURLResponse else {
            throw FalServiceError.invalidResponse
        }

        // Log error response for debugging
        if httpResponse.statusCode != 200 {
            let errorString = String(data: submitData, encoding: .utf8) ?? "Unable to decode error"
            logger.error("❌ FAL API Error (Status \(httpResponse.statusCode)): \(errorString)")
            throw FalServiceError.invalidResponse
        }

        // Parse request ID
        let submitResult = try JSONDecoder().decode(SubmitResponse.self, from: submitData)

        // Poll for result
        return try await pollForVideoResult(requestId: submitResult.requestId, endpoint: endpoint)
    }

    // MARK: - Private Helpers

    private func pollForResult(requestId: String, endpoint: String) async throws -> String {
        let statusURL = URL(string: "\(baseURL)/\(endpoint)/requests/\(requestId)")!
        var statusRequest = URLRequest(url: statusURL)
        statusRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

        // Poll up to 60 seconds
        for attempt in 0..<30 {
            let (data, response) = try await session.data(for: statusRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw FalServiceError.invalidResponse
            }

            let result = try JSONDecoder().decode(StatusResponse.self, from: data)

            switch result.status {
            case "COMPLETED":
                guard let imageUrl = result.data?.images?.first?.url else {
                    throw FalServiceError.noImageGenerated
                }
                logger.info("✅ Image generated after \(attempt + 1) polling attempts")
                return imageUrl
            case "FAILED":
                logger.error("❌ Image generation failed")
                throw FalServiceError.generationFailed
            default:
                // Still processing, wait 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        logger.error("❌ Image generation timed out")
        throw FalServiceError.timeout
    }

    private func pollForVideoResult(requestId: String, endpoint: String) async throws -> String {
        let statusURL = URL(string: "\(baseURL)/\(endpoint)/requests/\(requestId)")!
        var statusRequest = URLRequest(url: statusURL)
        statusRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

        // Poll up to 2 minutes (video takes longer)
        for attempt in 0..<60 {
            let (data, response) = try await session.data(for: statusRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw FalServiceError.invalidResponse
            }

            let result = try JSONDecoder().decode(VideoStatusResponse.self, from: data)

            switch result.status {
            case "COMPLETED":
                guard let videoUrl = result.data?.video?.url else {
                    throw FalServiceError.noVideoGenerated
                }
                logger.info("✅ Video generated after \(attempt + 1) polling attempts")
                return videoUrl
            case "FAILED":
                logger.error("❌ Video generation failed")
                throw FalServiceError.generationFailed
            default:
                // Still processing, wait 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        logger.error("❌ Video generation timed out")
        throw FalServiceError.timeout
    }

    // MARK: - Demo Mode Helpers

    /// Returns a mock image URL based on the prompt (for demo/testing)
    private func mockImageURL(for prompt: String) -> String {
        // Use placeholder.com for free, reliable mock images
        // Different sizes/colors based on prompt keywords
        let lowerPrompt = prompt.lowercased()

        if lowerPrompt.contains("cat") || lowerPrompt.contains("kitten") {
            return "https://placehold.co/1024x1024/orange/white?text=Cat+Adventure"
        } else if lowerPrompt.contains("dog") || lowerPrompt.contains("puppy") {
            return "https://placehold.co/1024x1024/brown/white?text=Dog+Adventure"
        } else if lowerPrompt.contains("bird") || lowerPrompt.contains("parrot") {
            return "https://placehold.co/1024x1024/blue/white?text=Bird+Flying"
        } else if lowerPrompt.contains("space") {
            return "https://placehold.co/1024x1024/black/white?text=Space+Explorer"
        } else if lowerPrompt.contains("beach") || lowerPrompt.contains("ocean") {
            return "https://placehold.co/1024x1024/cyan/white?text=Beach+Fun"
        } else {
            return "https://placehold.co/1024x1024/purple/white?text=Pet+Video"
        }
    }

    /// Returns a mock video URL for demo mode using Apple's sample HLS streams.
    /// These are publicly available test videos that work reliably in AVPlayer.
    func mockVideoURL(for prompt: String) -> String {
        // Apple's sample HLS streams - these actually work in AVPlayer
        // See: https://developer.apple.com/streaming/examples/
        let lowerPrompt = prompt.lowercased()

        // Use different Apple sample streams based on prompt keywords
        // All these are real, working video URLs
        if lowerPrompt.contains("cat") || lowerPrompt.contains("kitten") {
            // Basic stream - 720p
            return "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
        } else if lowerPrompt.contains("dog") || lowerPrompt.contains("puppy") {
            // Advanced stream (HDR example)
            return "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8"
        } else if lowerPrompt.contains("space") || lowerPrompt.contains("adventure") {
            // IMG_0139 - another Apple sample
            return "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
        } else {
            // Default: basic 4x3 stream
            return "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        }
    }
}

// MARK: - Supporting Types

private struct SubmitResponse: Codable {
    let requestId: String

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
    }
}

private struct StatusResponse: Codable {
    let status: String
    let data: ImageData?

    struct ImageData: Codable {
        let images: [ImageOutput]?

        struct ImageOutput: Codable {
            let url: String
        }
    }
}

private struct VideoStatusResponse: Codable {
    let status: String
    let data: VideoData?

    struct VideoData: Codable {
        let video: VideoOutput?

        struct VideoOutput: Codable {
            let url: String
        }
    }
}

enum FalServiceError: LocalizedError {
    case invalidResponse
    case noImageGenerated
    case noVideoGenerated
    case generationFailed
    case timeout
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .noImageGenerated:
            return "No image was generated"
        case .noVideoGenerated:
            return "No video was generated"
        case .generationFailed:
            return "Generation failed"
        case .timeout:
            return "Request timed out"
        case .missingAPIKey:
            return "API key not configured"
        }
    }
}
