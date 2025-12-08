import XCTest
import SwiftData
@testable import Project_PawNova

/// Tests for PetVideo SwiftData model.
final class PetVideoTests: XCTestCase {

    // MARK: - Initialization

    func testInit_WithPromptOnly() {
        let video = PetVideo(prompt: "Cat in space")

        XCTAssertEqual(video.prompt, "Cat in space")
        XCTAssertNil(video.generatedURL)
        XCTAssertNil(video.sourcePhotoURL)
        XCTAssertFalse(video.isFavorite)
        XCTAssertFalse(video.isGenerated)
    }

    func testInit_WithAllParameters() {
        let url = URL(string: "https://example.com/video.mp4")!
        let photoURL = URL(string: "https://example.com/photo.jpg")!
        let date = Date()

        let video = PetVideo(
            prompt: "Dog surfing",
            generatedURL: url,
            timestamp: date,
            sourcePhotoURL: photoURL
        )

        XCTAssertEqual(video.prompt, "Dog surfing")
        XCTAssertEqual(video.generatedURL, url)
        XCTAssertEqual(video.sourcePhotoURL, photoURL)
        XCTAssertEqual(video.timestamp, date)
        XCTAssertTrue(video.isGenerated)
    }

    // MARK: - Computed Properties

    func testPromptPreview_TruncatesLongPrompts() {
        let longPrompt = "This is a very long prompt that exceeds thirty characters"
        let video = PetVideo(prompt: longPrompt)

        XCTAssertEqual(video.promptPreview.count, 31) // 30 chars + ellipsis
        XCTAssertTrue(video.promptPreview.hasSuffix("…"))
    }

    func testPromptPreview_KeepsShortPrompts() {
        let shortPrompt = "Cat playing"
        let video = PetVideo(prompt: shortPrompt)

        XCTAssertEqual(video.promptPreview, shortPrompt)
    }

    func testIsGenerated_TrueWhenURLExists() {
        let video = PetVideo(prompt: "Test", generatedURL: URL(string: "https://x.com/v.mp4")!)
        XCTAssertTrue(video.isGenerated)
    }

    func testIsGenerated_FalseWhenNoURL() {
        let video = PetVideo(prompt: "Test")
        XCTAssertFalse(video.isGenerated)
    }

    // MARK: - Favorites

    func testIsFavorite_DefaultsFalse() {
        let video = PetVideo(prompt: "Test")
        XCTAssertFalse(video.isFavorite)
    }

    func testIsFavorite_CanBeToggled() {
        let video = PetVideo(prompt: "Test")
        video.isFavorite = true
        XCTAssertTrue(video.isFavorite)
        video.isFavorite = false
        XCTAssertFalse(video.isFavorite)
    }

    // MARK: - SwiftData Integration

    @MainActor
    func testSwiftData_PersistsAndFetches() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PetVideo.self, configurations: config)
        let context = ModelContext(container)

        let video = PetVideo(prompt: "Parrot flying", generatedURL: URL(string: "https://x.com/v.mp4")!)
        context.insert(video)
        try context.save()

        let descriptor = FetchDescriptor<PetVideo>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.prompt, "Parrot flying")
        XCTAssertTrue(fetched.first?.isGenerated ?? false)
    }

    @MainActor
    func testSwiftData_SortsByTimestamp() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PetVideo.self, configurations: config)
        let context = ModelContext(container)

        let old = PetVideo(prompt: "Old", timestamp: Date(timeIntervalSinceNow: -3600))
        let new = PetVideo(prompt: "New", timestamp: Date())

        context.insert(new)
        context.insert(old)
        try context.save()

        let descriptor = FetchDescriptor<PetVideo>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sorted = try context.fetch(descriptor)

        XCTAssertEqual(sorted[0].prompt, "New")
        XCTAssertEqual(sorted[1].prompt, "Old")
    }

    // MARK: - Sample Data

    #if DEBUG
    func testSamples_ReturnsThreeVideos() {
        let samples = PetVideo.samples()
        XCTAssertEqual(samples.count, 3)
        XCTAssertTrue(samples.allSatisfy { !$0.prompt.isEmpty })
    }
    #endif
}
