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
    case projects = 0
    case create = 1
    case settings = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .projects: return "Projects"
        case .create: return "Create"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .projects: return "video.fill"
        case .create: return "wand.and.stars"
        case .settings: return "person.fill"
        }
    }
}

// MARK: - Tab Router

/// Observable router for programmatic tab navigation.
/// Use `@Observable` (iOS 17+) for cleaner, more efficient observation.
@Observable
final class TabRouter {
    /// The currently selected tab (Projects is default/home).
    var selectedTab: AppTab = .projects

    /// Switches to the specified tab.
    func navigate(to tab: AppTab) {
        selectedTab = tab
    }

    /// Switches to the Projects tab.
    func goToProjects() {
        selectedTab = .projects
    }

    /// Switches to the Create tab.
    func goToCreate() {
        selectedTab = .create
    }

    /// Switches to the Settings tab.
    func goToSettings() {
        selectedTab = .settings
    }
}
