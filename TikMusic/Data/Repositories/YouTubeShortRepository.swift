import Foundation

/// Repository triển khai `ShortRepositoryProtocol` bằng YouTube Data API v3.
///
/// Luồng xử lý:
/// 1. Gọi endpoint `shortsSearch` (với `videoDuration=short` + `videoEmbeddable=true`)
///    để lấy danh sách video ngắn theo chế độ (trending / newest / tag / search).
/// 2. Gọi endpoint `videos` để bổ sung thống kê (lượt xem, thích, bình luận,
///    thời lượng) — giúp hiển thị số liệu ngay trên feed.
/// 3. Cache metadata + thumbnail xuống đĩa để xem offline.
struct YouTubeShortRepository: ShortRepositoryProtocol {

    /// Client gửi request (retry, timeout, decode...).
    private let client: APIClient

    /// Cung cấp API Key hiệu dụng.
    private let apiKeyProvider: APIKeyProvider

    /// Mã vùng dùng để lọc kết quả (rỗng = toàn cầu).
    private let regionCode: String

    /// Số kết quả mỗi trang.
    private let maxResultsPerPage: Int

    /// Từ khoá nền cho feed thịnh hành / mới nhất.
    private let baseQuery: String

    /// Store metadata offline.
    private let cacheStore: ShortCacheStore

    /// Khởi tạo repository.
    init(
        client: APIClient,
        apiKeyProvider: APIKeyProvider,
        regionCode: String = "US",
        maxResultsPerPage: Int = 15,
        baseQuery: String = "music short",
        cacheStore: ShortCacheStore = ShortCacheStore(store: JSONFileStore(fileName: "shorts-cache.json"))
    ) {
        self.client = client
        self.apiKeyProvider = apiKeyProvider
        self.regionCode = regionCode
        self.maxResultsPerPage = maxResultsPerPage
        self.baseQuery = baseQuery
        self.cacheStore = cacheStore
    }

    // MARK: - ShortRepositoryProtocol

    /// Lấy Short thịnh hành (theo lượt xem).
    func fetchTrendingShorts(pageToken: String?) async throws -> ShortVideoPage {
        try await fetch(query: baseQuery, order: "viewCount", pageToken: pageToken)
    }

    /// Lấy Short mới nhất (theo ngày đăng).
    func fetchNewestShorts(pageToken: String?) async throws -> ShortVideoPage {
        try await fetch(query: baseQuery, order: "date", pageToken: pageToken)
    }

    /// Lấy Short theo tag.
    func fetchByTag(_ tag: String, pageToken: String?) async throws -> ShortVideoPage {
        let query = tag.hasPrefix("#") ? String(tag.dropFirst()) : tag
        return try await fetch(query: query, order: "relevance", pageToken: pageToken)
    }

    /// Tìm kiếm Short theo từ khoá (artist/title/tag).
    func searchShorts(query: String, pageToken: String?) async throws -> ShortVideoPage {
        try await fetch(query: query, order: "relevance", pageToken: pageToken)
    }

    /// Tải trước trang tiếp theo (dùng chung logic lấy dữ liệu).
    func prefetchNext(pageToken: String?) async throws -> ShortVideoPage {
        try await fetchTrendingShorts(pageToken: pageToken)
    }

    /// Lọc video embeddable được (dùng `part=status`).
    func filterEmbeddable(ids: [String]) async throws -> [String] {
        guard !ids.isEmpty else { return [] }

        let key = try apiKey()
        let endpoint = YouTubeEndpoint.videoStatus(apiKey: key, ids: ids)
        let response = try await client.send(endpoint, as: YouTubeVideosResponseDTO.self)

        return (response.items ?? []).compactMap { item -> String? in
            guard let id = item.id, item.status?.embeddable == true else { return nil }
            return id
        }
    }

    /// Cache metadata + thumbnail offline.
    func cacheVideos(_ videos: [ShortVideo]) async throws {
        cacheStore.save(videos)
    }

    /// Đọc Short đã cache (dùng khi mất mạng).
    func loadCachedVideos() async throws -> [ShortVideo] {
        cacheStore.load()
    }

    // MARK: - Private

    /// Lấy Short theo query + order, kèm bổ sung thống kê.
    private func fetch(query: String, order: String?, pageToken: String?) async throws -> ShortVideoPage {
        let key = try apiKey()
        let endpoint = YouTubeEndpoint.shortsSearch(
            apiKey: key,
            query: query,
            pageToken: pageToken,
            maxResults: maxResultsPerPage,
            regionCode: regionCode,
            order: order
        )

        let response = try await client.send(endpoint, as: YouTubeSearchResponseDTO.self)
        let shorts = (response.items ?? []).compactMap {
            ShortVideoMapper.short(from: $0)
        }

        // Bổ sung thống kê (lượt xem, thích, bình luận, thời lượng).
        let enriched = try await enrichWithStatistics(shorts)
        return ShortVideoPage(videos: enriched, nextPageToken: response.nextPageToken)
    }

    /// Bổ sung lượt xem/lượt thích/lượt bình luận/thời lượng cho danh sách.
    private func enrichWithStatistics(_ shorts: [ShortVideo]) async throws -> [ShortVideo] {
        guard !shorts.isEmpty else { return shorts }

        let key = try apiKey()
        let ids = shorts.map(\.id)
        let endpoint = YouTubeEndpoint.videos(apiKey: key, ids: ids)
        let response = try await client.send(endpoint, as: YouTubeVideosResponseDTO.self)

        // Map id → DTO để trộn thông tin.
        let statsMap = Dictionary(
            uniqueKeysWithValues: (response.items ?? []).compactMap { item -> (String, YouTubeVideoItemDTO)? in
                guard let id = item.id else { return nil }
                return (id, item)
            }
        )

        return shorts.map { short in
            guard let item = statsMap[short.id] else { return short }
            return ShortVideoMapper.mergingStatistics(from: item, into: short)
        }
    }

    /// Lấy API Key hiệu dụng, ném lỗi nếu chưa cấu hình.
    private func apiKey() throws -> String {
        guard let key = apiKeyProvider.effectiveKey else {
            throw APIError.missingAPIKey
        }
        return key
    }
}
