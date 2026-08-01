import Foundation
import Observation
import SwiftUI

/// ViewModel cho feed Short (video dọc kiểu TikTok).
///
/// Chịu trách nhiệm:
/// - Giữ chế độ feed (trending / newest / tag / search) và danh sách Short.
/// - Phân trang (infinite scroll) + prefetch trang kế tiếp.
/// - Quản lý video đang hiển thị (autoplay/pause) và xử lý lỗi player
///   ("Video hiện không khả dụng" → chuyển video kế tiếp, không crash).
/// - Yêu thích, lịch sử xem (gần đây + tiếp tục xem), cache offline.
@Observable
@MainActor
final class ShortsViewModel {

    // MARK: - State

    /// Chế độ feed hiện tại.
    private(set) var mode: ShortsFeedMode = .trending

    /// Danh sách Short của feed hiện tại.
    private(set) var shorts: [ShortVideo] = []

    /// Token trang tiếp theo (nil = hết dữ liệu).
    private(set) var nextPageToken: String?

    /// Trạng thái tải dữ liệu.
    private(set) var state: ViewState = .idle

    /// Đang tải thêm trang tiếp theo.
    private(set) var isLoadingMore = false

    /// Index của Short đang hiển thị.
    private(set) var currentIndex = 0

    /// Set các ID Short không phát được (bị cấm nhúng) — hiển thị thông báo.
    private(set) var unavailableIDs: Set<String> = []

    /// Set các ID Short đang nằm trong danh sách yêu thích (cho UI phản ứng).
    private(set) var favoriteIDs: Set<String> = []

    /// Đang chuyển sang video kế tiếp sau lỗi không.
    private(set) var isSkipping = false

    /// Có hiển thị lịch sử xem không.
    var isShowingHistory = false

    /// Có đang tìm kiếm trong Short không.
    var isSearching = false

    /// Từ khoá tìm kiếm trong Short.
    var searchText = ""

    // MARK: - Dependencies

    private let shortsUseCase: ShortsUseCase
    private let favoritesUseCase: FavoritesUseCase
    private let historyStore: ShortHistoryStore
    private let apiKeyProvider: APIKeyProvider

    /// Số thế hệ tải — giúp bỏ kết quả cũ khi tải lại nhanh.
    private var loadGeneration = 0

    /// Timer ghi nhận vị trí phát định kỳ (continue watching).
    private var progressTask: Task<Void, Never>?
    /// Khởi tạo ViewModel.
    init(
        shortsUseCase: ShortsUseCase,
        favoritesUseCase: FavoritesUseCase,
        historyStore: ShortHistoryStore,
        apiKeyProvider: APIKeyProvider
    ) {
        self.shortsUseCase = shortsUseCase
        self.favoritesUseCase = favoritesUseCase
        self.historyStore = historyStore
        self.apiKeyProvider = apiKeyProvider
    }

    // MARK: - Public API

    /// API Key chưa được cấu hình.
    var isMissingAPIKey: Bool { !apiKeyProvider.isConfigured }

    /// Lịch sử xem gần đây.
    var recentEntries: [ShortHistoryStore.Entry] {
        historyStore.recentEntries
    }

    /// Danh sách "tiếp tục xem".
    var continueWatchingEntries: [ShortHistoryStore.Entry] {
        historyStore.continueWatchingEntries
    }

    /// Vị trí phát cuối cùng của một Short (để tiếp tục xem).
    func lastPlayedSeconds(for short: ShortVideo) -> Int {
        Int(historyStore.lastPlayedSeconds(id: short.id))
    }

    /// Short đang hiển thị (nil nếu chưa có dữ liệu).
    var currentShort: ShortVideo? {
        guard shorts.indices.contains(currentIndex) else { return nil }
        return shorts[currentIndex]
    }

    /// Một Short có nằm trong danh sách yêu thích không.
    func isFavorite(_ short: ShortVideo) -> Bool {
        favoriteIDs.contains(short.id)
    }

    /// Bật/tắt yêu thích một Short.
    func toggleFavorite(_ short: ShortVideo) {
        do {
            if favoriteIDs.contains(short.id) {
                try favoritesUseCase.remove(videoID: short.id)
                favoriteIDs.remove(short.id)
            } else {
                try favoritesUseCase.add(short.asMusicVideo)
                favoriteIDs.insert(short.id)
            }
        } catch {
            AppLogger.error("Lỗi thao tác yêu thích Short: \(error.localizedDescription)")
        }
    }

    /// Nạp lại các ID yêu thích từ store (gọi khi feed được mở).
    func refreshFavorites() {
        let favorites = (try? favoritesUseCase.fetchAll()) ?? []
        favoriteIDs = Set(favorites.map(\.id))
    }

    // MARK: - Loading

    /// Chọn chế độ feed khác (trending / newest / tag / search).
    func selectMode(_ newMode: ShortsFeedMode) {
        guard newMode != mode else { return }
        mode = newMode
        resetFeed()
    }

    /// Tải dữ liệu lần đầu cho chế độ hiện tại.
    func reload() async {
        loadGeneration += 1
        let currentGeneration = loadGeneration

        state = .loading
        shorts = []
        nextPageToken = nil
        unavailableIDs = []
        currentIndex = 0

        do {
            let page = try await shortsUseCase.fetch(mode: mode, pageToken: nil)
            guard currentGeneration == loadGeneration, !Task.isCancelled else { return }

            shorts = page.videos
            nextPageToken = page.nextPageToken
            state = shorts.isEmpty ? .empty : .loaded

            // Cache metadata + thumbnail offline.
            if !shorts.isEmpty {
                try? await shortsUseCase.cacheVideos(shorts)
            }
        } catch is CancellationError {
            // Người dùng đổi chế độ giữa chừng — bỏ qua.
        } catch {
            guard currentGeneration == loadGeneration, !Task.isCancelled else { return }
            // Nếu có dữ liệu cache thì dùng tạm (offline).
            if let cached = try? await shortsUseCase.loadCachedVideos(), !cached.isEmpty {
                shorts = cached
                nextPageToken = nil
                state = .loaded
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    /// Chọn một Short theo index (autoplay đúng video hiển thị).
    func select(index: Int) {
        guard shorts.indices.contains(index) else { return }
        currentIndex = index
        recordWatchIfNeeded()
        prefetchIfNeeded()
    }

    /// Cập nhật vị trí phát hiện tại (gọi từ callback `onTimeUpdate` của player).
    func updateProgress(seconds: Double) {
        guard let short = currentShort, !short.id.isEmpty else { return }
        historyStore.updateProgress(id: short.id, seconds: seconds)
    }

    /// Tải thêm trang kế tiếp khi cuộn đến video cuối.
    func loadMoreIfNeeded(current video: ShortVideo) async {
        guard state == .loaded, !isLoadingMore, let token = nextPageToken else { return }
        guard shorts.last?.id == video.id else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await shortsUseCase.fetch(mode: mode, pageToken: token)
            guard !Task.isCancelled else { return }
            // Tránh thêm trùng ID (phòng khi API trả trùng lặp).
            let knownIDs = Set(shorts.map(\.id))
            shorts += page.videos.filter { !knownIDs.contains($0.id) }
            nextPageToken = page.nextPageToken

            // Cache metadata + thumbnail offline.
            if !page.videos.isEmpty {
                try? await shortsUseCase.cacheVideos(page.videos)
            }
        } catch {
            AppLogger.error("loadMore Short thất bại: \(error.localizedDescription)")
        }
    }

    /// Tải trước trang kế tiếp trong nền (prefetch).
    func prefetchIfNeeded() {
        guard state == .loaded, !isLoadingMore, let token = nextPageToken else { return }
        // Chỉ prefetch khi đang ở 3 video cuối.
        guard currentIndex >= shorts.count - 3 else { return }

        Task {
            isLoadingMore = true
            defer { isLoadingMore = false }
            do {
                let page = try await shortsUseCase.prefetchNext(mode: mode, pageToken: token)
                guard !Task.isCancelled else { return }
                let knownIDs = Set(shorts.map(\.id))
                shorts += page.videos.filter { !knownIDs.contains($0.id) }
                nextPageToken = page.nextPageToken
                if !page.videos.isEmpty {
                    try? await shortsUseCase.cacheVideos(page.videos)
                }
            } catch {
                AppLogger.error("prefetch Short thất bại: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Search & Tag

    /// Bắt đầu tìm kiếm trong Short.
    func startSearch() {
        isSearching = true
        isShowingHistory = false
    }

    /// Hủy tìm kiếm.
    func cancelSearch() {
        isSearching = false
        searchText = ""
    }

    /// Thực hiện tìm kiếm theo từ khoá.
    func submitSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = false
        selectMode(.search(query))
        Task { await reload() }
    }

    /// Lọc feed theo tag (chạm vào tag trên video).
    func filterByTag(_ tag: String) {
        selectMode(.tag(tag))
        Task { await reload() }
    }

    // MARK: - Player errors

    /// Xử lý lỗi player: đánh dấu "không khả dụng" và chuyển video kế tiếp.
    ///
    /// - Parameter shortID: ID Short gặp lỗi.
    func handlePlayerError(shortID: String) {
        guard let index = shorts.firstIndex(where: { $0.id == shortID }) else { return }
        unavailableIDs.insert(shortID)

        // Chỉ tự chuyển video kế tiếp khi video lỗi đang được hiển thị.
        guard index == currentIndex, !isSkipping else { return }
        guard shorts.indices.contains(index + 1) else { return }

        isSkipping = true
        let nextIndex = index + 1

        // Trì hoãn ngắn để hiển thị thông báo "Video hiện không khả dụng".
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            currentIndex = nextIndex
            isSkipping = false
            recordWatchIfNeeded()
            prefetchIfNeeded()
        }
    }

    /// Ghi nhận một lần xem vào lịch sử.
    func recordWatchIfNeeded() {
        guard let short = currentShort, !short.id.isEmpty else { return }
        historyStore.record(short: short, seconds: historyStore.lastPlayedSeconds(id: short.id))
    }

    /// Mở lại một Short từ lịch sử (tiếp tục đúng vị trí đã dừng).
    func resume(entry: ShortHistoryStore.Entry) {
        isShowingHistory = false
        selectMode(.trending)

        // Nếu Short đã có trong feed thì nhảy tới index tương ứng.
        if let index = shorts.firstIndex(where: { $0.id == entry.id }) {
            select(index: index)
            return
        }

        // Ngược lại chèn Short vào đầu feed rồi nhảy tới.
        Task {
            await reload()
            if let index = shorts.firstIndex(where: { $0.id == entry.id }) {
                select(index: index)
            } else {
                let existing = shorts
                shorts = [entry.short] + existing
                state = .loaded
                currentIndex = 0
            }
        }
    }

    /// Xoá toàn bộ lịch sử xem.
    func clearHistory() {
        historyStore.clear()
    }

    // MARK: - Progress tracking (continue watching)

    /// Dừng theo dõi vị trí (khi đóng feed).
    func stopProgressTracking() {
        progressTask?.cancel()
        progressTask = nil
    }

    // MARK: - Private

    /// Reset toàn bộ feed khi đổi chế độ.
    private func resetFeed() {
        loadGeneration += 1
        shorts = []
        nextPageToken = nil
        unavailableIDs = []
        currentIndex = 0
        state = .idle
        stopProgressTracking()
    }
}
