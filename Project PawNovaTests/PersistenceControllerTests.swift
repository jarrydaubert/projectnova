import XCTest
import SwiftData
@testable import Project_PawNova

/// Tests for SwiftData persistence layer.
@MainActor
final class PersistenceControllerTests: XCTestCase {

    // MARK: - Container Tests

    func testSharedInstance_IsSingleton() {
        let instance1 = PersistenceController.shared
        let instance2 = PersistenceController.shared
        XCTAssertTrue(instance1 === instance2, "Should return same instance")
    }

    func testSharedInstance_HasContainer() {
        let controller = PersistenceController.shared
        XCTAssertNotNil(controller.container)
    }

    func testSharedInstance_HasMainContext() {
        let controller = PersistenceController.shared
        XCTAssertNotNil(controller.mainContext)
    }

    func testNewContext_ReturnsModelContext() {
        let controller = PersistenceController.shared
        let context = controller.newContext()
        XCTAssertNotNil(context)
    }

    // Note: Parallel in-memory container tests are flaky due to SwiftData
    // concurrency limitations. Real persistence is tested via PetVideoTests.
}
