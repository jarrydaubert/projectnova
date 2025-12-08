//
//  TabRouter.swift
//  Project PawNova
//
//  Modern tab navigation using iOS 17's @Observable macro.
//  Use this to programmatically switch tabs from any view.
//

import SwiftUI

// MARK: - Tab Enum

/// Defines the available tabs in the app.
enum AppTab: Int, CaseIterable, Identifiable {
    case create = 0
    case library = 1
    case settings = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .create: return "Create"
        case .library: return "Library"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .create: return "plus.circle.fill"
        case .library: return "film.stack"
        case .settings: return "gear"
        }
    }
}

// MARK: - Tab Router

/// Observable router for programmatic tab navigation.
/// Use `@Observable` (iOS 17+) for cleaner, more efficient observation.
@Observable
final class TabRouter {
    /// The currently selected tab.
    var selectedTab: AppTab = .create

    /// Switches to the specified tab.
    func navigate(to tab: AppTab) {
        selectedTab = tab
    }

    /// Switches to the Create tab.
    func goToCreate() {
        selectedTab = .create
    }

    /// Switches to the Library tab.
    func goToLibrary() {
        selectedTab = .library
    }

    /// Switches to the Settings tab.
    func goToSettings() {
        selectedTab = .settings
    }
}
