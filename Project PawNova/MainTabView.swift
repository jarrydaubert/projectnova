import SwiftUI
import SwiftData

struct MainTabView: View {
    /// Tab router for programmatic navigation.
    /// Using @State with @Observable (iOS 17+) for efficient updates.
    @State private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // Projects Tab (Home/Landing)
            ProjectsView()
                .tabItem {
                    Label(AppTab.projects.title, systemImage: AppTab.projects.icon)
                }
                .tag(AppTab.projects)

            // Create Tab
            ContentView()
                .tabItem {
                    Label(AppTab.create.title, systemImage: AppTab.create.icon)
                }
                .tag(AppTab.create)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(.pawPrimary)
        .preferredColorScheme(.dark)
        .environment(router)  // iOS 17+ environment injection for @Observable
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: PetVideo.self, inMemory: true)
}
