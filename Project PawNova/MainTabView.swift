import SwiftUI
import SwiftData

struct MainTabView: View {
    /// Tab router for programmatic navigation.
    /// Using @State with @Observable (iOS 17+) for efficient updates.
    @State private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // Create Tab
            ContentView()
                .tabItem {
                    Label(AppTab.create.title, systemImage: AppTab.create.icon)
                }
                .tag(AppTab.create)

            // Library Tab
            LibraryView()
                .tabItem {
                    Label(AppTab.library.title, systemImage: AppTab.library.icon)
                }
                .tag(AppTab.library)

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
