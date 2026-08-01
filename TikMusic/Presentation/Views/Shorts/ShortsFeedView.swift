import SwiftUI

/// Feed Short dạng video dọc toàn màn hình (kiểu TikTok).
///
/// - Cuộn dọc, mỗi trang một video (paging).
/// - Tự động phát video đang hiển thị, tạm dừng video trước.
/// - Preload video kế tiếp (giữ tối đa 3 trong RAM, giải phóng video cũ).
/// - Xử lý lỗi player: "Video hiện không khả dụng" → chuyển video kế tiếp.
struct ShortsFeedView: View {

    /// ViewModel của feed.
    @Bindable var viewModel: ShortsViewModel

    /// ID Short đang hiển thị trong scroll view (nguồn truth cho paging).
    @State private var scrollID: String?

    /// Đóng feed.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .idle:
                Color.black.ignoresSafeArea()
            case .loading:
                skeletonFeed
            case .loaded:
                feed
            case .empty:
                emptyView
            case .error(let message):
                if viewModel.isMissingAPIKey {
                    missingAPIKeyView
                } else {
                    errorView(message)
                }
            }
        }
        .statusBarHidden(true)
        .ignoresSafeArea(.container)
        .task {
            viewModel.refreshFavorites()
            if viewModel.state == .idle {
                await viewModel.reload()
            }
        }
        .onChange(of: viewModel.shorts) { oldShorts, newShorts in
            // Khi feed thay đổi (đổi chế độ / tải lại), cuộn về đầu.
            guard let first = newShorts.first, first.id != oldShorts.first?.id else { return }
            scrollID = first.id
        }
        .onChange(of: viewModel.currentIndex) { _, newIndex in
            // Đồng bộ khi ViewModel nhảy tới video khác (resume, bỏ qua lỗi).
            let id = viewModel.shorts.indices.contains(newIndex) ? viewModel.shorts[newIndex].id : nil
            if let id, id != scrollID {
                scrollID = id
            }
        }
        .onDisappear {
            viewModel.stopProgressTracking()
        }
        .fullScreenCover(isPresented: $viewModel.isShowingHistory) {
            ShortsHistoryView(
                viewModel: viewModel,
                recentEntries: viewModel.recentEntries,
                continueWatchingEntries: viewModel.continueWatchingEntries
            )
        }
    }

    // MARK: - Feed (paging dọc)

    private var feed: some View {
        let currentIndex = viewModel.shorts.firstIndex { $0.id == scrollID }

        return ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.shorts.enumerated()), id: \.element.id) { index, short in
                    ShortPageView(
                        short: short,
                        isActive: short.id == scrollID,
                        isPreloading: isPreloadingPage(at: index, currentIndex: currentIndex),
                        isUnavailable: viewModel.unavailableIDs.contains(short.id),
                        isFavorite: viewModel.isFavorite(short),
                        startSeconds: viewModel.lastPlayedSeconds(for: short),
                        onToggleFavorite: {
                            viewModel.toggleFavorite(short)
                        },
                        onTagTap: { tag in
                            viewModel.filterByTag(tag)
                        },
                        onPlayerError: { _ in
                            viewModel.handlePlayerError(shortID: short.id)
                        },
                        onTimeUpdate: { seconds in
                            if short.id == scrollID {
                                viewModel.updateProgress(seconds: seconds)
                            }
                        }
                    )
                    .id(short.id)
                    .containerRelativeFrame(.vertical)
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .containerRelativeFrame(.vertical)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollID)
        .onChange(of: scrollID) { _, newID in
            guard let newID,
                  let index = viewModel.shorts.firstIndex(where: { $0.id == newID }) else { return }
            viewModel.select(index: index)
            Task { await viewModel.loadMoreIfNeeded(current: viewModel.shorts[index]) }
        }
        .overlay(alignment: .top) {
            topBar
        }
    }

    /// Trang được preload: là trang kế tiếp của video đang xem.
    ///
    /// Chỉ preload trang kế tiếp (chưa phát, không phát âm thanh) và chỉ khi
    /// feed còn dữ liệu. Các trang khác hiển thị thumbnail để giải phóng player.
    private func isPreloadingPage(at index: Int, currentIndex: Int?) -> Bool {
        guard let currentIndex else { return false }
        return index == currentIndex + 1
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 16) {
            // Nút đóng.
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.4), in: Circle())
            }

            Spacer()

            Text("Short")
                .font(AppTheme.headlineFont.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            // Lịch sử xem.
            Button {
                viewModel.isShowingHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.4), in: Circle())
            }

            // Tìm kiếm trong Short.
            Button {
                viewModel.startSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.4), in: Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .sheet(isPresented: $viewModel.isSearching) {
            shortsSearchSheet
        }
    }

    // MARK: - Search sheet

    private var shortsSearchSheet: some View {
        NavigationStack {
            ShortSearchView(viewModel: viewModel)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Skeleton

    private var skeletonFeed: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProgressView()
                .tint(.white.opacity(0.6))
        }
    }

    // MARK: - Empty / Error

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.7))
            Text("Chưa có Short nào")
                .font(AppTheme.titleFont)
                .foregroundStyle(.white)
            Text("Không tìm thấy video ngắn nào cho chế độ này.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Thử lại") {
                Task { await viewModel.reload() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.7))
            Text("Đã có lỗi xảy ra")
                .font(AppTheme.titleFont)
                .foregroundStyle(.white)
            Text(message)
                .font(AppTheme.bodyFont)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Thử lại") {
                Task { await viewModel.reload() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }

    private var missingAPIKeyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accentGradient)
            Text("Chưa cấu hình API Key")
                .font(AppTheme.titleFont)
                .foregroundStyle(.white)
            Text("Thêm YouTube Data API Key trong Cài đặt để xem Short.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ShortsFeedView(viewModel: ShortsViewModel(
        shortsUseCase: ShortsUseCase(
            repository: YouTubeShortRepository(
                client: APIClient(session: URLSession.shared),
                apiKeyProvider: APIKeyProvider(),
                cacheStore: ShortCacheStore(store: JSONFileStore(inMemory: "preview-shorts.json"))
            )
        ),
        favoritesUseCase: FavoritesUseCase(repository: PreviewData.previewFavoritesRepository),
        historyStore: ShortHistoryStore(store: JSONFileStore(inMemory: "preview-history.json")),
        apiKeyProvider: APIKeyProvider()
    ))
}
