import XCTest
import SwiftData
@testable import Project_PawNova

/// Integration tests for core app workflows.
@MainActor
final class Project_PawNovaTests: XCTestCase {

    var persistence: PersistenceController!

    override func setUpWithError() throws {
        persistence = PersistenceController(inMemory: true)
    }

    // MARK: - Core Workflow Tests

    func testWorkflow_CreateAndSaveVideo() throws {
        let context = persistence.mainContext

        let video = PetVideo(
            prompt: "Cat as space explorer",
            generatedURL: URL(string: "https://example.com/cat.mp4")
        )
        context.insert(video)
        try context.save()

        let descriptor = FetchDescriptor<PetVideo>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.prompt, "Cat as space explorer")
        XCTAssertTrue(fetched.first?.isGenerated ?? false)
    }

    func testWorkflow_DeleteVideo() throws {
        let context = persistence.mainContext

        let video = PetVideo(prompt: "Test deletion")
        context.insert(video)
        try context.save()

        context.delete(video)
        try context.save()

        let descriptor = FetchDescriptor<PetVideo>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 0)
    }

    func testWorkflow_FavoriteVideo() throws {
        let context = persistence.mainContext

        let video = PetVideo(prompt: "Favorite test")
        context.insert(video)

        XCTAssertFalse(video.isFavorite)
        video.isFavorite = true
        try context.save()

        let descriptor = FetchDescriptor<PetVideo>()
        let fetched = try context.fetch(descriptor)

        XCTAssertTrue(fetched.first?.isFavorite ?? false)
    }

    func testWorkflow_MultipleVideosSortedByDate() throws {
        let context = persistence.mainContext

        let videos = [
            PetVideo(prompt: "Old", timestamp: Date(timeIntervalSinceNow: -3600)),
            PetVideo(prompt: "Newest", timestamp: Date()),
            PetVideo(prompt: "Middle", timestamp: Date(timeIntervalSinceNow: -1800))
        ]

        videos.forEach { context.insert($0) }
        try context.save()

        let descriptor = FetchDescriptor<PetVideo>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sorted = try context.fetch(descriptor)

        XCTAssertEqual(sorted[0].prompt, "Newest")
        XCTAssertEqual(sorted[1].prompt, "Middle")
        XCTAssertEqual(sorted[2].prompt, "Old")
    }
}
