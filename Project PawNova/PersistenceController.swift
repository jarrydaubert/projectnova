//
//  PersistenceController.swift
//  Project PawNova
//
//  Created by Jarryd Aubert on 04/12/2025.
//

import Foundation
import os
import SwiftData

// MARK: - Logging

private let logger = Logger(subsystem: "com.pawnova.PawNova", category: "Persistence")

/// A lightweight SwiftData container manager.
/// Use `PersistenceController.shared` for production and `PersistenceController.preview` for SwiftUI previews and tests.
final class PersistenceController {
    static let shared = PersistenceController()

    #if DEBUG
    static let preview: PersistenceController = {
        PersistenceController(inMemory: true)
    }()
    #endif

    let container: ModelContainer

    /// The main context for use on the main actor (e.g., in SwiftUI views).
    var mainContext: ModelContext { container.mainContext }

    /// Create a new context for background work.
    func newContext() -> ModelContext { ModelContext(container) }

    init(inMemory: Bool = false) {
        let schema = Schema([
            PetVideo.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            logger.info("✅ ModelContainer created successfully (inMemory: \(inMemory))")
        } catch {
            if inMemory {
                // For in-memory: Try with a unique identifier to avoid conflicts
                logger.warning("⚠️ In-memory ModelContainer failed: \(error.localizedDescription). Retrying...")

                // Add a small delay to avoid rapid concurrent container creation issues
                Thread.sleep(forTimeInterval: 0.05)

                do {
                    // Retry with a fresh configuration
                    let retryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    container = try ModelContainer(for: schema, configurations: [retryConfig])
                    logger.info("✅ In-memory ModelContainer created successfully on retry")
                } catch let retryError {
                    // Last resort: Create with simplified in-memory configuration
                    logger.warning("❌ Retry failed: \(retryError.localizedDescription). Creating with simplified fallback.")
                    let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                    do {
                        container = try ModelContainer(for: PetVideo.self, configurations: fallbackConfig)
                        logger.info("✅ Fallback container created successfully")
                    } catch {
                        // If all else fails, use default in-memory container
                        logger.fault("💥 Failed to create in-memory ModelContainer after all retry attempts: \(error.localizedDescription)")
                        fatalError("Failed to create in-memory ModelContainer after all retry attempts: \(error)")
                    }
                }
            } else {
                logger.fault("💥 Failed to create ModelContainer: \(error.localizedDescription)")
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }

        #if DEBUG
        if inMemory {
            // Optional: Disable saves in previews to prevent mutations.
            container.mainContext.autosaveEnabled = false
        }
        #endif
    }
}
