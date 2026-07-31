import SwiftUI

/// Màn hình Trang chủ.
///
/// Hiển thị: tiêu đề, thanh tìm kiếm, các chủ đề nhạc (TikTok Viral, Trending,
/// Remix, Mashup, Phonk, Chill, Sad, EDM, Nightcore, KPOP, USUK, Anime, Lofi)
/// và lưới video tương ứng.
///
/// Hỗ trợ: infinite scroll, pull to refresh, skeleton loading, empty/error view.
struct HomeView: View {

    /// ViewModel của màn hình.
    @Bindable var viewModel: HomeViewModel

    /// Container tiêm phụ thuộc.
    @Environment(DependencyContainer.self) private var container

    /// Namespace cho hero animation (zoom transition).
    @Namespace private var zoomNamespace

    /// Có hiển thị sheet tìm kiếm không.
    @State private var isSearchPresented = false

    /// Cột của lưới video (2 cột).
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header
                    searchButton
                    categoryCarousel
                    content
                }
                .padding(.horizontal, AppTheme.padding)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .refreshable {
                await viewModel.reload()
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MusicVideo.self) { video in
                VideoDetailView(viewModel: container.makeVideoDetailViewModel(video: video))
                    .heroZoom(sourceID: video.id, in: zoomNamespace)
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView(viewModel: container.settingsViewModel)
                }
            }
        }
        .task(id: viewModel.selectedCategory) {
            // Chỉ tải lần đầu / sau khi đổi chủ đề (đổi chủ đề reset state = .idle).
            guard viewModel.state == .idle else { return }
            await viewModel.reload()
        }
        .fullScreenCover(isPresented: $isSearchPresented) {
            SearchView(viewModel: container.searchViewModel)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TikMusic")
                    .font(AppTheme.largeTitleFont)
                    .foregroundStyle(AppTheme.accentGradient)
                Text("Tổng hợp video nhạc viral")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Biểu tượng nốt nhạc trang trí.
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient)
                    .frame(width: 42, height: 42)
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Search bar

    private var searchButton: some View {
        Button {
            isSearchPresented = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.accent)
                Text("Tìm kiếm bài hát, ca sĩ...")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category carousel

    private var categoryCarousel: some View {
        CategoryCarouselView(
            categories: viewModel.categories,
            selection: viewModel.selectedCategoryBinding
        )
    }

    // MARK: - Content theo state

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            skeletonGrid
        case .loaded:
            videoGrid
        case .empty:
            EmptyStateView(
                symbolName: "music.note.list",
                title: "Không có video",
                message: "Không tìm thấy video nào cho chủ đề này. Vui lòng thử lại sau."
            )
        case .error(let message):
            if viewModel.isMissingAPIKey {
                missingAPIKeyView
            } else {
                ErrorStateView(message: message) {
                    Task { await viewModel.reload() }
                }
            }
        }
    }

    // MARK: - Video grid

    private var videoGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.videos) { video in
                NavigationLink(value: video) {
                    VideoCardView(video: video)
                        .heroSource(id: video.id, in: zoomNamespace)
                }
                .buttonStyle(.plain)
                .onAppear {
                    // Khi video cuối xuất hiện → tải trang tiếp theo.
                    Task { await viewModel.loadMoreIfNeeded(current: video) }
                }
            }

            // Footer loading khi đang tải thêm.
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Skeleton loading

    private var skeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonImageBlock()
                    SkeletonView(height: 14)
                    SkeletonView(cornerRadius: 6, height: 12)
                }
            }
        }
    }

    // MARK: - Thiếu API Key

    private var missingAPIKeyView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "key.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(AppTheme.accentGradient)
            }

            Text("Chưa cấu hình API Key")
                .font(AppTheme.titleFont)

            Text("Thêm YouTube Data API Key trong Cài đặt để bắt đầu sử dụng TikMusic.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NavigationLink(value: HomeRoute.settings) {
                Label("Mở Cài đặt", systemImage: "gearshape.fill")
                    .font(AppTheme.headlineFont)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

/// Route điều hướng nội bộ của Trang chủ.
private enum HomeRoute: Hashable {
    case settings
}

#Preview {
    HomeView(viewModel: HomeViewModel(
        fetchVideosUseCase: FetchVideosUseCase(
            repository: YouTubeVideoRepository(
                client: APIClient(session: URLSession.shared),
                apiKeyProvider: APIKeyProvider()
            )
        ),
        apiKeyProvider: APIKeyProvider()
    ))
    .environment(DependencyContainer())
}
