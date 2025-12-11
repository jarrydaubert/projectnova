//
//  FoundationModelService.swift
//  Project PawNova
//
//  On-device AI prompt enhancement using Apple Intelligence (iOS 18.1+).
//  Uses the Foundation Models framework for local LLM inference.
//
//  Falls back to hardcoded enhancement for devices without Apple Intelligence.
//

import Foundation

// MARK: - Foundation Models Import (iOS 18.1+)

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Enhanced Prompt Result

/// Result of prompt enhancement with additional suggestions
struct EnhancedPromptResult {
    /// The enhanced cinematic prompt
    let enhancedPrompt: String

    /// Suggested visual style
    let suggestedStyle: String?

    /// Suggested camera movement
    let cameraMovement: String?

    /// Whether enhancement was done on-device
    let wasOnDevice: Bool

    /// Raw prompt if enhancement failed
    static func fallback(_ prompt: String) -> EnhancedPromptResult {
        EnhancedPromptResult(
            enhancedPrompt: prompt,
            suggestedStyle: nil,
            cameraMovement: nil,
            wasOnDevice: false
        )
    }
}

// MARK: - Foundation Model Service

@MainActor
final class FoundationModelService {
    static let shared = FoundationModelService()

    private init() {}

    /// Check if Apple Intelligence is available on this device
    var isAppleIntelligenceAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    /// Enhance a prompt using on-device AI or fallback
    func enhancePrompt(_ prompt: String, petName: String? = nil) async -> EnhancedPromptResult {
        // Try on-device enhancement first
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAppleIntelligenceAvailable {
            if let result = await enhanceWithFoundationModel(prompt, petName: petName) {
                return result
            }
        }
        #endif

        // Fallback to hardcoded enhancement
        return enhanceWithFallback(prompt, petName: petName)
    }

    // MARK: - On-Device Enhancement (iOS 26.0+)

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func enhanceWithFoundationModel(_ prompt: String, petName: String?) async -> EnhancedPromptResult? {
        do {
            let session = LanguageModelSession()

            // Build the system context
            let petContext = petName.map { "The pet's name is \($0). " } ?? ""
            let instructions = """
            You are a creative video prompt enhancer for AI pet video generation.
            \(petContext)
            Enhance the user's prompt to be more cinematic and detailed.
            Add visual details, lighting, and mood while keeping it natural.
            Keep the response under 100 words. Return only the enhanced prompt text.
            """

            // Generate enhanced prompt using the new API
            let response = try await session.respond(
                to: "\(instructions)\n\nOriginal prompt: \(prompt)"
            )

            // Extract the enhanced prompt from the response
            let enhanced = String(response.content).trimmingCharacters(in: .whitespacesAndNewlines)

            DiagnosticsService.shared.info("On-device prompt enhancement successful", category: "FoundationModel")

            return EnhancedPromptResult(
                enhancedPrompt: enhanced.isEmpty ? prompt : enhanced,
                suggestedStyle: nil,  // Could parse from response
                cameraMovement: nil,  // Could parse from response
                wasOnDevice: true
            )
        } catch {
            DiagnosticsService.shared.warning("Foundation Model enhancement failed: \(error)", category: "FoundationModel")
            return nil
        }
    }
    #else
    private func enhanceWithFoundationModel(_ prompt: String, petName: String?) async -> EnhancedPromptResult? {
        return nil
    }
    #endif

    // MARK: - Fallback Enhancement

    private func enhanceWithFallback(_ prompt: String, petName: String?) -> EnhancedPromptResult {
        let lowercased = prompt.lowercased()

        // Don't enhance already detailed prompts
        if prompt.count > 200 ||
           lowercased.contains("cinematic") ||
           lowercased.contains("dramatic") ||
           lowercased.contains("beautiful") {
            return EnhancedPromptResult(
                enhancedPrompt: prompt,
                suggestedStyle: nil,
                cameraMovement: nil,
                wasOnDevice: false
            )
        }

        // Check for pet mentions
        let petKeywords = ["dog", "cat", "puppy", "kitten", "pet", "pup", "kitty",
                          "golden retriever", "labrador", "bulldog", "poodle",
                          "persian", "siamese", "tabby", "corgi", "husky"]
        let hasPetMention = petKeywords.contains { lowercased.contains($0) }

        // Build enhanced prompt
        var enhanced = ""

        // Add cinematic prefix
        if hasPetMention {
            enhanced = "Adorable, heartwarming video of "
        } else {
            enhanced = "Cinematic, high-quality video of "
        }

        // Add pet name if available
        if let name = petName, !lowercased.contains(name.lowercased()) {
            enhanced += "\(name) the pet: "
        }

        // Add original prompt
        enhanced += prompt

        // Add visual enhancements
        let visualEnhancements = [
            "with soft natural lighting",
            "beautiful bokeh background",
            "warm golden hour tones",
            "professional cinematography"
        ]

        // Pick 1-2 enhancements based on prompt hash for consistency
        let hash = prompt.hashValue
        let enhancement1 = visualEnhancements[abs(hash) % visualEnhancements.count]
        let enhancement2 = visualEnhancements[abs(hash / 4) % visualEnhancements.count]

        if enhancement1 != enhancement2 {
            enhanced += ", \(enhancement1), \(enhancement2)"
        } else {
            enhanced += ", \(enhancement1)"
        }

        return EnhancedPromptResult(
            enhancedPrompt: enhanced,
            suggestedStyle: "Cinematic",
            cameraMovement: "Slow dolly",
            wasOnDevice: false
        )
    }

    // MARK: - Smart Suggestions

    /// Generate prompt suggestions based on pet name and history
    func generateSuggestions(petName: String?, previousPrompts: [String]) async -> [String] {
        // Basic suggestions based on pet name
        let name = petName ?? "your pet"
        var suggestions = [
            "\(name) exploring a magical forest",
            "\(name) as a superhero saving the day",
            "\(name) playing on a sunny beach",
            "\(name) in a cozy coffee shop",
            "\(name) having a space adventure"
        ]

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAppleIntelligenceAvailable {
            // Try to get AI-generated suggestions
            if let aiSuggestions = await generateAISuggestions(petName: name, previousPrompts: previousPrompts) {
                suggestions = aiSuggestions
            }
        }
        #endif

        return suggestions
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateAISuggestions(petName: String, previousPrompts: [String]) async -> [String]? {
        do {
            let session = LanguageModelSession()

            let previousContext = previousPrompts.isEmpty
                ? ""
                : "Previous prompts: \(previousPrompts.prefix(3).joined(separator: ", ")). Generate different ideas."

            let response = try await session.respond(
                to: """
                Generate 5 creative, fun video ideas for a pet named \(petName).
                \(previousContext)
                Return only the ideas, one per line, no numbering.
                Keep each under 10 words.
                """
            )

            let responseText = String(response.content)
            let suggestions = responseText
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .prefix(5)

            return suggestions.isEmpty ? nil : Array(suggestions)
        } catch {
            return nil
        }
    }
    #endif
}

// MARK: - Integration with FalService

extension FalService {
    /// Enhanced prompt generation using Foundation Models when available
    func enhancePromptWithAI(_ prompt: String, petName: String? = nil) async -> String {
        let result = await FoundationModelService.shared.enhancePrompt(prompt, petName: petName)
        return result.enhancedPrompt
    }
}
