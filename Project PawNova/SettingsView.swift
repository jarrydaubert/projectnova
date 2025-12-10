import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(OnboardingManager.self) private var onboarding
    @Query private var videos: [PetVideo]

    @State private var showClearDataAlert = false
    @State private var showResetOnboardingAlert = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var notificationsEnabled = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pawBackground.ignoresSafeArea()

                List {
                    // Account Section
                    Section {
                        if onboarding.isAuthenticated {
                            // Signed in state
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(LinearGradient.pawPrimary)
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(onboarding.userName.isEmpty ? "PawNova User" : onboarding.userName)
                                        .font(.headline)
                                        .foregroundColor(.pawTextPrimary)
                                    Text("Signed in with Apple")
                                        .font(.caption)
                                        .foregroundColor(.pawTextSecondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 8)

                            // Sign Out button
                            Button {
                                showSignOutAlert = true
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.pawTextPrimary)
                            }
                        } else {
                            // Not signed in state
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(LinearGradient.pawPrimary)
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sign In")
                                        .font(.headline)
                                        .foregroundColor(.pawTextPrimary)
                                    Text("Sync videos across devices")
                                        .font(.caption)
                                        .foregroundColor(.pawTextSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.pawTextSecondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(Color.pawCard)

                    // Subscription Section
                    Section {
                        Button {
                            Haptic.light()
                            showPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("PawNova Pro")
                                        .font(.headline)
                                        .foregroundColor(.pawTextPrimary)
                                    Text("Unlimited videos, HD export")
                                        .font(.caption)
                                        .foregroundColor(.pawTextSecondary)
                                }

                                Spacer()

                                Text("Upgrade")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(LinearGradient.pawPrimary)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("Subscription")
                            .foregroundColor(.pawTextSecondary)
                    }
                    .listRowBackground(Color.pawCard)

                    // Storage Section
                    Section {
                        HStack {
                            Label("Videos Created", systemImage: "film.stack")
                                .foregroundColor(.pawTextPrimary)
                            Spacer()
                            Text("\(videos.count)")
                                .foregroundColor(.pawTextSecondary)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Label("Favorites", systemImage: "star.fill")
                                .foregroundColor(.pawTextPrimary)
                            Spacer()
                            Text("\(videos.filter { $0.isFavorite }.count)")
                                .foregroundColor(.pawTextSecondary)
                                .fontWeight(.medium)
                        }
                    } header: {
                        Text("Storage")
                            .foregroundColor(.pawTextSecondary)
                    }
                    .listRowBackground(Color.pawCard)

                    // Notifications Section
                    Section {
                        HStack {
                            Label("Notifications", systemImage: "bell.fill")
                                .foregroundColor(.pawTextPrimary)
                            Spacer()
                            if notificationStatus == .authorized {
                                Text("On")
                                    .foregroundColor(.pawSuccess)
                                    .font(.subheadline)
                            } else if notificationStatus == .denied {
                                Button("Enable") {
                                    openNotificationSettings()
                                }
                                .font(.subheadline)
                                .foregroundColor(.pawPrimary)
                            } else {
                                Button("Set Up") {
                                    requestNotificationPermission()
                                }
                                .font(.subheadline)
                                .foregroundColor(.pawPrimary)
                            }
                        }

                        if notificationStatus == .authorized {
                            HStack {
                                Label("Video Ready Alerts", systemImage: "film")
                                    .foregroundColor(.pawTextPrimary)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.pawSuccess)
                            }
                        }
                    } header: {
                        Text("Notifications")
                            .foregroundColor(.pawTextSecondary)
                    } footer: {
                        if notificationStatus == .denied {
                            Text("Notifications are disabled. Tap 'Enable' to open Settings.")
                                .foregroundColor(.pawTextSecondary)
                        }
                    }
                    .listRowBackground(Color.pawCard)

                    // Support Section
                    Section {
                        NavigationLink {
                            FAQView()
                        } label: {
                            Label("Help Center", systemImage: "questionmark.circle")
                                .foregroundColor(.pawTextPrimary)
                        }

                        Link(destination: URL(string: "mailto:support@pawnova.app")!) {
                            HStack {
                                Label("Contact Support", systemImage: "envelope")
                                    .foregroundColor(.pawTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.pawTextSecondary)
                            }
                        }

                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundColor(.pawTextPrimary)
                        }

                        NavigationLink {
                            TermsOfServiceView()
                        } label: {
                            Label("Terms of Service", systemImage: "doc.text")
                                .foregroundColor(.pawTextPrimary)
                        }
                    } header: {
                        Text("Support")
                            .foregroundColor(.pawTextSecondary)
                    }
                    .listRowBackground(Color.pawCard)

                    // Danger Zone
                    Section {
                        Button(role: .destructive) {
                            showClearDataAlert = true
                        } label: {
                            Label("Delete All Videos", systemImage: "trash")
                                .foregroundColor(.pawError)
                        }

                        Button(role: .destructive) {
                            showDeleteAccountAlert = true
                        } label: {
                            Label("Delete Account & Data", systemImage: "person.crop.circle.badge.xmark")
                                .foregroundColor(.pawError)
                        }
                    } header: {
                        Text("Danger Zone")
                            .foregroundColor(.pawTextSecondary)
                    } footer: {
                        Text("Deleting your account will permanently remove all your data including videos, settings, and subscription information.")
                            .foregroundColor(.pawTextSecondary)
                    }
                    .listRowBackground(Color.pawCard)

                    // Diagnostics Section
                    Section {
                        NavigationLink {
                            DiagnosticsView()
                        } label: {
                            Label("Diagnostics", systemImage: "stethoscope")
                                .foregroundColor(.pawTextPrimary)
                        }
                    } header: {
                        Text("Troubleshooting")
                            .foregroundColor(.pawTextSecondary)
                    }
                    .listRowBackground(Color.pawCard)

                    // Developer Options (DEBUG only)
                    #if DEBUG
                    Section {
                        Button {
                            showResetOnboardingAlert = true
                        } label: {
                            Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                                .foregroundColor(.pawPrimary)
                        }

                        Button {
                            TipConfiguration.resetAllTips()
                            Haptic.success()
                        } label: {
                            Label("Reset Tips", systemImage: "lightbulb")
                                .foregroundColor(.pawPrimary)
                        }
                    } header: {
                        Text("Developer")
                            .foregroundColor(.pawTextSecondary)
                    }
                    .listRowBackground(Color.pawCard)
                    #endif

                    // Footer
                    Section {
                        EmptyView()
                    } footer: {
                        VStack(spacing: 8) {
                            Text("PawNova v1.0.0")
                                .font(.caption)
                                .foregroundColor(.pawTextSecondary)

                            Text("© 2025 PawNova")
                                .font(.caption2)
                                .foregroundColor(.pawTextSecondary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .alert("Delete All Videos?", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all \(videos.count) videos. This cannot be undone.")
            }
            .alert("Reset Onboarding?", isPresented: $showResetOnboardingAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    onboarding.reset()
                    Haptic.success()
                }
            } message: {
                Text("This will reset onboarding so you can test the flow again.")
            }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("You can sign back in anytime to sync your videos across devices.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Account", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
            .onAppear {
                checkNotificationStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkNotificationStatus()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(showDismissButton: true)
            }
        }
    }

    private func clearAllData() {
        for video in videos {
            modelContext.delete(video)
        }
        try? modelContext.save()
        Haptic.success()
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                checkNotificationStatus()
                if granted {
                    Haptic.success()
                }
            }
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func signOut() {
        // Clear authentication state
        onboarding.isAuthenticated = false
        onboarding.userName = ""

        // Clear credentials from keychain if needed
        // AuthenticationServices handles Sign in with Apple revocation

        Haptic.success()
    }

    private func deleteAccount() {
        // Delete all videos
        for video in videos {
            modelContext.delete(video)
        }
        try? modelContext.save()

        // Clear all user data
        onboarding.reset()

        // Clear secure Keychain data (credits and subscription)
        SecureUserData.shared.resetAll()

        // In production: Also call backend API to delete server-side data
        // and revoke Sign in with Apple credentials

        Haptic.success()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: PetVideo.self, inMemory: true)
        .environment(OnboardingManager())
}
