import SwiftUI
import SwiftData

struct MainTabView: View {
    /// Tab router for programmatic navigation.
    /// Using @State with @Observable (iOS 17+) for efficient updates.
    @State private var router = TabRouter()

    /// Detect if running on iPad for adaptive layout
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // Projects Tab (Home/Landing)
            Tab(AppTab.projects.title, systemImage: AppTab.projects.icon, value: AppTab.projects) {
                ProjectsView()
            }

            // Create Tab
            Tab(AppTab.create.title, systemImage: AppTab.create.icon, value: AppTab.create) {
                ContentView()
            }

            // Settings Tab
            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: AppTab.settings) {
                SettingsView()
            }
        }
        // iOS 18: Floating tab bar that transforms to sidebar on iPad
        .tabViewStyle(.sidebarAdaptable)
        .tint(.pawPrimary)
        .preferredColorScheme(.dark)
        .environment(router)  // iOS 17+ environment injection for @Observable
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: PetVideo.self, inMemory: true)
}
