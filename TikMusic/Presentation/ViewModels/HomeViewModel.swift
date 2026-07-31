import Foundation
import Observation
import SwiftUI

/// ViewModel cho màn hình Trang chủ.
///
/// Chịu trách nhiệm:
/// - Giữ chủ đề đang chọn và danh sách video tương ứng.
/// - Tải dữ liệu lần đầu / kéo để làm mới.
/// - Phân trang (infinite scroll) khi cuộn đến cuối.
/// - Quản lý trạng thái loading / empty / error.
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - State

    /// Chủ đề đang chọn.
    private(set) var selectedCategory: MusicCategory

    /// Danh sách video của chủ đề hiện tại.
    private(set) var videos: [MusicVideo] = []

    /// Token trang tiếp theo (nil = hết dữ liệu).
    private(set) var nextPageToken: String?

    /// Trạng thái tải dữ liệu.
    private(set) var state: ViewState = .idle

    /// Đang tải thêm trang tiếp theo.
    private(set) var isLoadingMore = false

    // MARK: - Dependencies

    private let fetchVideosUseCase: FetchVideosUseCase
    private let apiKeyProvider: APIKeyProvider

    /// Số thế hệ tải — giúp bỏ kết quả cũ khi tải lại nhanh.
    private var loadGeneration = 0

    /// Khởi tạo ViewModel.
    init(
        fetchVideosUseCase: FetchVideosUseCase,
        apiKeyProvider: APIKeyProvider,
        initialCategory: MusicCategory = .tiktokViral
    ) {
        self.fetchVideosUseCase = fetchVideosUseCase
        self.apiKeyProvider = apiKeyProvider
        self.selectedCategory = initialCategory
    }

    // MARK: - Public API

    /// Danh sách tất cả chủ đề.
    var categories: [MusicCategory] { MusicCategory.allCases }

    /// Binding cho chủ đề đang chọn (dùng trong CategoryCarouselView).
    var selectedCategoryBinding: Binding<MusicCategory> {
        Binding(
            get: { self.selectedCategory },
            set: { self.select($0) }
        )
    }

    /// API Key chưa được cấu hình.
    var isMissingAPIKey: Bool { !apiKeyProvider.isConfigured }

    /// Chọn chủ đề khác.
    func select(_ category: MusicCategory) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        videos = []
        nextPageToken = nil
        state = .idle
    }

    /// Tải lại dữ liệu của chủ đề hiện tại (kéo để làm mới / đổi chủ đề).
    func reload() async {
        loadGeneration += 1
        let currentGeneration = loadGeneration

        state = .loading
        videos = []
        nextPageToken = nil

        do {
            let page = try await fetchVideosUseCase.execute(
                category: selectedCategory,
                pageToken: nil
            )
            // Bỏ qua nếu đã có lần tải mới hơn.
            guard currentGeneration == loadGeneration, !Task.isCancelled else { return }

            videos = page.videos
            nextPageToken = page.nextPageToken
            state = videos.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // Người dùng đổi chủ đề giữa chừng — bỏ qua.
        } catch {
            guard currentGeneration == loadGeneration, !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }

    /// Tải thêm trang tiếp theo khi người dùng cuộn đến video cuối.
    func loadMoreIfNeeded(current video: MusicVideo) async {
        guard state == .loaded, !isLoadingMore, let token = nextPageToken else { return }
        guard videos.last?.id == video.id else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchVideosUseCase.execute(
                category: selectedCategory,
                pageToken: token
            )
            guard !Task.isCancelled else { return }
            // Tránh thêm trùng ID (phòng khi API trả trùng lặp).
            let knownIDs = Set(videos.map(\.id))
            videos += page.videos.filter { !knownIDs.contains($0.id) }
            nextPageToken = page.nextPageToken
        } catch {
            // Lỗi tải thêm: giữ nguyên dữ liệu hiện có, không làm phiền người dùng.
            AppLogger.error("loadMore thất bại: \(error.localizedDescription)")
        }
    }
}
