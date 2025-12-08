import XCTest
@testable import Project_PawNova

/// Tests for FalService - focused on AI model properties and error handling.
/// Real API tests should be integration tests, not unit tests.
@MainActor
final class FalServiceTests: XCTestCase {

    // MARK: - AI Model Tests

    func testAIModel_Veo3FastProperties() {
        let model = AIModel.veo3Fast
        XCTAssertEqual(model.displayName, "Veo 3 Fast")
        XCTAssertEqual(model.provider, "Google")
        XCTAssertEqual(model.duration, "8s")
        XCTAssertEqual(model.credits, 800)
        XCTAssertTrue(model.supportsAudio)
    }

    func testAIModel_Veo3StandardProperties() {
        let model = AIModel.veo3Standard
        XCTAssertEqual(model.displayName, "Veo 3 Pro")
        XCTAssertEqual(model.provider, "Google")
        XCTAssertEqual(model.duration, "8s")
        XCTAssertEqual(model.credits, 2000)
        XCTAssertTrue(model.supportsAudio)
    }

    func testAIModel_Kling25Properties() {
        let model = AIModel.kling25
        XCTAssertEqual(model.displayName, "Kling 2.5")
        XCTAssertEqual(model.provider, "Kuaishou")
        XCTAssertEqual(model.duration, "5s")
        XCTAssertEqual(model.credits, 600)
        XCTAssertFalse(model.supportsAudio)
    }

    func testAIModel_Hailuo02Properties() {
        let model = AIModel.hailuo02
        XCTAssertEqual(model.displayName, "Hailuo AI")
        XCTAssertEqual(model.provider, "MiniMax")
        XCTAssertEqual(model.duration, "6s")
        XCTAssertEqual(model.credits, 500)
        XCTAssertFalse(model.supportsAudio)
    }

    func testAIModel_AllCasesCount() {
        XCTAssertEqual(AIModel.allCases.count, 4)
    }

    func testAIModel_RawValuesAreEndpoints() {
        XCTAssertEqual(AIModel.veo3Fast.rawValue, "fal-ai/veo3/fast")
        XCTAssertEqual(AIModel.veo3Standard.rawValue, "fal-ai/veo3")
        XCTAssertEqual(AIModel.kling25.rawValue, "fal-ai/kling-video/v2.5/pro/text-to-video")
        XCTAssertEqual(AIModel.hailuo02.rawValue, "fal-ai/minimax/hailuo-02/pro/text-to-video")
    }

    func testAIModel_HasDescriptions() {
        for model in AIModel.allCases {
            XCTAssertFalse(model.description.isEmpty, "\(model) should have a description")
        }
    }

    // MARK: - Demo Mode Tests

    func testDemoMode_IsEnabledByDefault() {
        // Create a fresh instance to test default state
        let service = FalService()
        XCTAssertTrue(service.demoMode, "Demo mode should be enabled by default")
    }

    func testDemoMode_CanBeToggled() {
        let service = FalService()
        XCTAssertTrue(service.demoMode, "Should start in demo mode")

        service.demoMode = false
        XCTAssertFalse(service.demoMode, "Should be able to disable demo mode")

        service.demoMode = true
        XCTAssertTrue(service.demoMode, "Should be able to re-enable demo mode")
    }

    // MARK: - Error Types

    func testFalServiceError_HasDescriptions() {
        XCTAssertNotNil(FalServiceError.invalidResponse.errorDescription)
        XCTAssertNotNil(FalServiceError.noVideoGenerated.errorDescription)
        XCTAssertNotNil(FalServiceError.generationFailed.errorDescription)
        XCTAssertNotNil(FalServiceError.timeout.errorDescription)
        XCTAssertNotNil(FalServiceError.missingAPIKey.errorDescription)
    }

    func testFalServiceError_DescriptionsAreUserFriendly() {
        XCTAssertEqual(FalServiceError.invalidResponse.errorDescription, "Invalid response from server")
        XCTAssertEqual(FalServiceError.noVideoGenerated.errorDescription, "No video was generated")
        XCTAssertEqual(FalServiceError.generationFailed.errorDescription, "Generation failed")
        XCTAssertEqual(FalServiceError.timeout.errorDescription, "Request timed out")
        XCTAssertEqual(FalServiceError.missingAPIKey.errorDescription, "API key not configured")
    }

    // MARK: - Prompt Enhancement Tests

    func testEnhancePrompt_AddsCinematicToShortPrompt() {
        let service = FalService()
        let enhanced = service.enhancePrompt("cat playing")

        XCTAssertTrue(enhanced.contains("Cinematic"), "Should add cinematic quality")
        XCTAssertTrue(enhanced.contains("cat playing"), "Should preserve original prompt")
    }

    func testEnhancePrompt_AddsPetEnhancement() {
        let service = FalService()
        let enhanced = service.enhancePrompt("dog running")

        XCTAssertTrue(enhanced.contains("Adorable"), "Should add pet-specific enhancement")
    }

    func testEnhancePrompt_SkipsAlreadyEnhancedPrompts() {
        let service = FalService()
        let alreadyEnhanced = "Cinematic video of a cat in space"
        let result = service.enhancePrompt(alreadyEnhanced)

        XCTAssertEqual(result, alreadyEnhanced, "Should not double-enhance")
    }

    func testEnhancePrompt_SkipsLongPrompts() {
        let service = FalService()
        let longPrompt = String(repeating: "word ", count: 50)
        let result = service.enhancePrompt(longPrompt)

        XCTAssertEqual(result, longPrompt, "Long prompts should be returned as-is")
    }

    func testEnhancePrompt_NonPetPrompt_NoAdorable() {
        let service = FalService()
        let enhanced = service.enhancePrompt("sunset over mountains")

        XCTAssertTrue(enhanced.contains("Cinematic"), "Should add cinematic quality")
        XCTAssertFalse(enhanced.contains("Adorable"), "Should not add pet enhancement for non-pet prompt")
    }
}
