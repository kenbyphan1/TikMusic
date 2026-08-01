import Foundation

/// UseCase cho feed Short (video dọc kiểu TikTok).
///
/// Đóng gói các quy trình nghiệp vụ của module Short, che giấu chi tiết
/// triển khai của `ShortRepositoryProtocol` cho tầng Presentation:
/// - Lấy danh sách theo nhiều chế độ (thịnh hành / mới / tag / tìm kiếm).
/// - Tải trước (prefetch) trang kế tiếp để phát mượt.
/// - Cache metadata offline.
struct ShortsUseCase {

    private let repository: ShortRepositoryProtocol

    init(repository: ShortRepositoryProtocol) {
        self.repository = repository
    }

    /// Lấy Short theo chế độ hiện tại.
    ///
    /// - Parameters:
    ///   - mode: chế độ feed (trending / newest / tag / search).
    ///   - pageToken: token trang tiếp theo.
    func fetch(mode: ShortsFeedMode, pageToken: String?) async throws -> ShortVideoPage {
        switch mode {
        case .trending:
            return try await repository.fetchTrendingShorts(pageToken: pageToken)
        case .newest:
            return try await repository.fetchNewestShorts(pageToken: pageToken)
        case .tag(let tag):
            return try await repository.fetchByTag(tag, pageToken: pageToken)
        case .search(let query):
            return try await repository.searchShorts(query: query, pageToken: pageToken)
        }
    }

    /// Tải trước trang tiếp theo cho chế độ hiện tại.
    ///
    /// Gọi song song với chế độ đang xem để feed sẵn sàng khi cuộn xuống.
    func prefetchNext(mode: ShortsFeedMode, pageToken: String?) async throws -> ShortVideoPage {
        try await fetch(mode: mode, pageToken: pageToken)
    }

    /// Lọc video embeddable được.
    func filterEmbeddable(ids: [String]) async throws -> [String] {
        try await repository.filterEmbeddable(ids: ids)
    }

    /// Cache metadata + thumbnail offline.
    func cacheVideos(_ videos: [ShortVideo]) async throws {
        try await repository.cacheVideos(videos)
    }

    /// Đọc Short đã cache.
    func loadCachedVideos() async throws -> [ShortVideo] {
        try await repository.loadCachedVideos()
    }
}

/// Chế độ của feed Short.
enum ShortsFeedMode: Hashable, Sendable {
    /// Đang thịnh hành.
    case trending

    /// Mới nhất.
    case newest

    /// Theo tag.
    case tag(String)

    /// Theo từ khoá tìm kiếm.
    case search(String)

    /// Tiêu đề hiển thị cho từng chế độ.
    var title: String {
        switch self {
        case .trending: return "Trending"
        case .newest: return "Mới nhất"
        case .tag(let tag): return "#\(tag)"
        case .search(let query): return query
        }
    }
}
