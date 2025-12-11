import SwiftUI
import SwiftData
import AVKit

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabRouter.self) private var router: TabRouter?
    @Query(sort: \PetVideo.timestamp, order: .reverse) private var videos: [PetVideo]

    @State private var selectedVideo: PetVideo?
    @State private var showingVideoDetail = false
    @State private var searchText = ""

    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var filteredVideos: [PetVideo] {
        if searchText.isEmpty {
            return videos
        } else {
            return videos.filter { $0.prompt.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.pawBackground.ignoresSafeArea()

                if videos.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Stats card
                            statsCard

                            // Video grid
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredVideos) { video in
                                    VideoThumbnailCard(video: video)
                                        .onTapGesture {
                                            selectedVideo = video
                                            showingVideoDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .searchable(text: $searchText, prompt: "Search your adventures")
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showingVideoDetail) {
                if let video = selectedVideo {
                    VideoDetailView(video: video)
                }
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "film.stack",
                value: "\(videos.count)",
                label: "Videos"
            )

            Divider()
                .frame(height: 40)
                .background(Color.pawTextSecondary.opacity(0.3))

            StatItem(
                icon: "clock.fill",
                value: totalDuration,
                label: "Total Time"
            )

            Divider()
                .frame(height: 40)
                .background(Color.pawTextSecondary.opacity(0.3))

            StatItem(
                icon: "star.fill",
                value: "\(favoriteCount)",
                label: "Favorites"
            )
        }
        .padding()
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var totalDuration: String {
        let totalSeconds = videos.count * 8 // Assuming 8s average
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else {
            return "\(totalSeconds / 60)m"
        }
    }

    private var favoriteCount: Int {
        videos.filter { $0.isFavorite }.count
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.stack")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient.pawPrimary)

            VStack(spacing: 8) {
                Text("No Adventures Yet")
                    .font(.title2.bold())
                    .foregroundColor(.pawTextPrimary)

                Text("Create your first pet video to get started")
                    .font(.subheadline)
                    .foregroundColor(.pawTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                // Use router to switch to Create tab (proper tab navigation)
                router?.goToCreate()
                Haptic.medium()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Adventure")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 200)
                .background(LinearGradient.pawPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.pawAccent)

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.pawTextPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(.pawTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Video Thumbnail Card

struct VideoThumbnailCard: View {
    let video: PetVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pawCard)
                    .aspectRatio(16 / 9, contentMode: .fit)

                // Play icon overlay
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(LinearGradient.pawPrimary)

                // Favorite badge
                if video.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.pawWarning)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.prompt)
                    .font(.caption.bold())
                    .foregroundColor(.pawTextPrimary)
                    .lineLimit(2)

                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(video.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                }
                .foregroundColor(.pawTextSecondary)
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: PetVideo.self, inMemory: true)
        .environment(TabRouter())
}
