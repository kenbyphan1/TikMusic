import Foundation
import Observation
import SwiftUI

/// ViewModel cho màn hình Tìm kiếm.
///
/// Chịu trách nhiệm:
/// - Debounce từ khoá (chỉ tìm sau khi người dùng dừng gõ).
/// - Quản lý lịch sử tìm kiếm và gợi ý.
/// - Tìm kiếm + phân trang kết quả.
/// - Quản lý trạng thái loading / empty / error.
@Observable
@MainActor
final class SearchViewModel {

    /// Độ trễ debounce (ms) khi người dùng gõ.
    static let debounceDelay: Duration = .milliseconds(500)

    /// Danh sách gợi ý phổ biến hiển thị khi chưa gõ gì.
    static let popularSuggestions: [String] = [
        "Phonk", "Mashup", "Nightcore", "Chill", "Lofi",
        "Anime Music", "EDM", "KPOP", "Sad Songs", "TikTok Viral",
    ]

    // MARK: - State

    /// Từ khoá đang gõ.
    private(set) var query = ""

    /// Kết quả tìm kiếm.
    private(set) var results: [MusicVideo] = []

    /// Token trang tiếp theo.
    private(set) var nextPageToken: String?

    /// Trạng thái tìm kiếm.
    private(set) var state: ViewState = .idle

    /// Đang tải thêm trang tiếp theo.
    private(set) var isLoadingMore = false

    // MARK: - Dependencies

    private let searchVideosUseCase: SearchVideosUseCase
    private let searchHistoryStore: SearchHistoryStore
    private let apiKeyProvider: APIKeyProvider

    // MARK: - Tasks

    private var debounceTask: Task<Void, Never>?

    /// Khởi tạo ViewModel.
    init(
        searchVideosUseCase: SearchVideosUseCase,
        searchHistoryStore: SearchHistoryStore,
        apiKeyProvider: APIKeyProvider
    ) {
        self.searchVideosUseCase = searchVideosUseCase
        self.searchHistoryStore = searchHistoryStore
        self.apiKeyProvider = apiKeyProvider
    }

    // MARK: - Public API

    /// API Key chưa được cấu hình.
    var isMissingAPIKey: Bool { !apiKeyProvider.isConfigured }

    /// Lịch sử tìm kiếm gần đây.
    var history: [String] { searchHistoryStore.recentSearches }

    /// Binding cho ô nhập từ khoá (dùng trong TextField).
    var queryBinding: Binding<String> {
        Binding(
            get: { self.query },
            set: { self.updateQuery($0) }
        )
    }

    /// Cập nhật từ khoá (debounced).
    ///
    /// - Parameter newQuery: từ khoá mới người dùng gõ.
    func updateQuery(_ newQuery: String) {
        query = newQuery

        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Xoá sạch kết quả khi người dùng xoá hết từ khoá.
            debounceTask?.cancel()
            results = []
            nextPageToken = nil
            state = .idle
            return
        }

        // Huỷ task debounce cũ, lên lịch tìm kiếm mới.
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: Self.debounceDelay)
            guard !Task.isCancelled else { return }
            await self?.performSearch(query: trimmed)
        }
    }

    /// Tìm kiếm ngay (nút search trên bàn phím hoặc chọn gợi ý).
    func searchNow(_ text: String? = nil) {
        let term = text ?? query
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        query = trimmed
        debounceTask?.cancel()
        searchHistoryStore.add(trimmed)
        Task { await performSearch(query: trimmed) }
    }

    /// Chọn một gợi ý / lịch sử tìm kiếm.
    func selectSuggestion(_ text: String) {
        searchNow(text)
    }

    /// Xoá một mục lịch sử.
    func removeHistoryItem(_ text: String) {
        searchHistoryStore.remove(text)
    }

    /// Xoá toàn bộ lịch sử.
    func clearHistory() {
        searchHistoryStore.clear()
    }

    /// Tải thêm trang kết quả tiếp theo.
    func loadMoreIfNeeded(current video: MusicVideo) async {
        guard state == .loaded, !isLoadingMore, let token = nextPageToken else { return }
        guard results.last?.id == video.id else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await searchVideosUseCase.execute(query: query, pageToken: token)
            guard !Task.isCancelled else { return }
            let knownIDs = Set(results.map(\.id))
            results += page.videos.filter { !knownIDs.contains($0.id) }
            nextPageToken = page.nextPageToken
        } catch {
            AppLogger.error("loadMore thất bại: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    /// Thực hiện tìm kiếm với từ khoá đã chuẩn hoá.
    private func performSearch(query: String) async {
        state = .loading
        results = []
        nextPageToken = nil

        do {
            let page = try await searchVideosUseCase.execute(query: query, pageToken: nil)
            guard !Task.isCancelled else { return }
            results = page.videos
            nextPageToken = page.nextPageToken
            state = results.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // Từ khoá thay đổi giữa chừng — bỏ qua.
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }
}
