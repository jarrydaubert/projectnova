//
//  ProjectsView.swift
//  Project PawNova
//
//  Main landing screen showing user's video projects.
//  Empty state prompts video creation, populated state shows project grid.
//

import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabRouter.self) private var router: TabRouter?
    @Query(sort: \PetVideo.timestamp, order: .reverse) private var videos: [PetVideo]

    private var userCredits: Int { SecureUserData.shared.credits }
    @State private var showPaywall = false
    @State private var showShowcase = false
    @State private var selectedVideo: PetVideo?
    @State private var showingVideoDetail = false

    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pawBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Create Video Button
                    createVideoButton
                        .padding(.horizontal)
                        .padding(.top, 16)

                    if videos.isEmpty {
                        // Empty State
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        // Projects Grid
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(videos) { video in
                                    ProjectCard(video: video)
                                        .onTapGesture {
                                            selectedVideo = video
                                            showingVideoDetail = true
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showPaywall) {
                PaywallView(showDismissButton: true)
            }
            .sheet(isPresented: $showingVideoDetail) {
                if let video = selectedVideo {
                    VideoDetailView(video: video)
                }
            }
            .sheet(isPresented: $showShowcase) {
                ShowcaseView {
                    showShowcase = false
                    router?.goToCreate()
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Projects")
                .font(.largeTitle.bold())
                .foregroundColor(.pawTextPrimary)

            Spacer()

            // Credits display
            Button {
                Haptic.light()
                showPaywall = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.pawWarning)
                    Text("\(userCredits)")
                        .font(.subheadline.bold())
                        .foregroundColor(.pawTextPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.pawCard)
                .clipShape(Capsule())
            }

            // Get PRO button
            Button {
                Haptic.light()
                showPaywall = true
            } label: {
                Text("Get PRO")
                    .font(.subheadline.bold())
                    .foregroundColor(.pawBackground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.pawTextPrimary)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Create Video Button

    private var createVideoButton: some View {
        Button {
            router?.goToCreate()
            Haptic.medium()
        } label: {
            HStack {
                Image(systemName: "video.fill")
                Text("Create Video")
                    .font(.headline.bold())
            }
            .foregroundColor(.pawBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.pawButton)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Video camera icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient.pawButton)
                    .frame(width: 80, height: 80)

                Image(systemName: "video.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.pawBackground)
            }

            VStack(spacing: 8) {
                Text("Ready to create amazing\nvideos?")
                    .font(.title2.bold())
                    .foregroundColor(.pawTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Start your first project and bring your\nideas to life with AI")
                    .font(.subheadline)
                    .foregroundColor(.pawTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // CTA Buttons
            VStack(spacing: 12) {
                Button {
                    router?.goToCreate()
                    Haptic.medium()
                } label: {
                    Text("Create Your First Video")
                        .font(.headline.bold())
                        .foregroundColor(.pawBackground)
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                        .background(LinearGradient.pawButton)
                        .clipShape(Capsule())
                }

                // See Examples button
                Button {
                    Haptic.light()
                    showShowcase = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                        Text("See Examples")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.pawPrimary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    let video: PetVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pawCard)
                    .aspectRatio(16 / 9, contentMode: .fit)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.pawPrimary)

                // Favorite badge
                if video.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.pawWarning)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }

            // Info
            Text(video.prompt)
                .font(.caption.bold())
                .foregroundColor(.pawTextPrimary)
                .lineLimit(2)

            Text(video.timestamp.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.pawTextSecondary)
        }
    }
}

#Preview("Empty State") {
    ProjectsView()
        .modelContainer(for: PetVideo.self, inMemory: true)
        .environment(TabRouter())
}

#Preview("With Videos") {
    let container = try! ModelContainer(for: PetVideo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let video1 = PetVideo(prompt: "Golden retriever running through a magical forest")
    let video2 = PetVideo(prompt: "Cat playing with butterflies in a garden")
    container.mainContext.insert(video1)
    container.mainContext.insert(video2)

    return ProjectsView()
        .modelContainer(container)
        .environment(TabRouter())
}
