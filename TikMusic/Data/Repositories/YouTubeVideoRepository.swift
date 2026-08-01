import Foundation

/// Repository triển khai `VideoRepositoryProtocol` bằng YouTube Data API v3.
///
/// Luồng xử lý:
/// 1. Gọi endpoint `search` để lấy danh sách video theo chủ đề/từ khoá.
/// 2. Gọi endpoint `videos` để bổ sung thống kê (lượt xem, thời lượng).
///    Điều này giúp hiển thị lượt xem ngay trên danh sách.
struct YouTubeVideoRepository: VideoRepositoryProtocol {

    /// Client gửi request (retry, timeout, decode...).
    private let client: APIClient

    /// Cung cấp API Key hiệu dụng.
    private let apiKeyProvider: APIKeyProvider

    /// Mã vùng dùng để lọc kết quả (rỗng = toàn cầu).
    private let regionCode: String

    /// Số kết quả mỗi trang.
    private let maxResultsPerPage: Int

    /// Khởi tạo repository.
    init(
        client: APIClient,
        apiKeyProvider: APIKeyProvider,
        regionCode: String = "US",
        maxResultsPerPage: Int = 20
    ) {
        self.client = client
        self.apiKeyProvider = apiKeyProvider
        self.regionCode = regionCode
        self.maxResultsPerPage = maxResultsPerPage
    }

    // MARK: - VideoRepositoryProtocol

    /// Lấy video theo chủ đề + bổ sung thống kê.
    func fetchVideos(category: MusicCategory, pageToken: String?) async throws -> VideoPage {
        let key = try apiKey()
        let endpoint = YouTubeEndpoint.search(
            apiKey: key,
            query: category.searchQuery,
            pageToken: pageToken,
            maxResults: maxResultsPerPage,
            regionCode: regionCode
        )

        let response = try await client.send(endpoint, as: YouTubeSearchResponseDTO.self)
        let videos = (response.items ?? [])
            .compactMap { MusicVideoMapper.video(from: $0, category: category) }

        // Bổ sung thống kê để hiển thị lượt xem.
        let enriched = try await enrichWithStatistics(videos)
        return VideoPage(videos: enriched, nextPageToken: response.nextPageToken)
    }

    /// Tìm kiếm video + bổ sung thống kê.
    func searchVideos(query: String, pageToken: String?) async throws -> VideoPage {
        let key = try apiKey()
        let endpoint = YouTubeEndpoint.search(
            apiKey: key,
            query: query,
            pageToken: pageToken,
            maxResults: maxResultsPerPage,
            regionCode: regionCode
        )

        let response = try await client.send(endpoint, as: YouTubeSearchResponseDTO.self)
        let videos = (response.items ?? []).compactMap { MusicVideoMapper.video(from: $0) }

        let enriched = try await enrichWithStatistics(videos)
        return VideoPage(videos: enriched, nextPageToken: response.nextPageToken)
    }

    /// Lấy chi tiết đầy đủ một video.
    func fetchVideoDetail(videoID: String) async throws -> MusicVideo {
        let key = try apiKey()
        let endpoint = YouTubeEndpoint.videos(apiKey: key, ids: [videoID])

        let response = try await client.send(endpoint, as: YouTubeVideosResponseDTO.self)
        guard let item = response.items?.first,
              let video = MusicVideoMapper.video(from: item) else {
            throw APIError.invalidResponse
        }
        return video
    }

    /// Lọc ra những video embeddable được từ danh sách ID.
    ///
    /// Dùng `part=status` (rẻ hơn `part=snippet,statistics`), chỉ trả về ID
    /// của những video có `status.embeddable == true`.
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

    // MARK: - Private

    /// Bổ sung lượt xem/lượt thích/thời lượng cho danh sách video.
    private func enrichWithStatistics(_ videos: [MusicVideo]) async throws -> [MusicVideo] {
        guard !videos.isEmpty else { return videos }

        let key = try apiKey()
        let ids = videos.map(\.id)
        let endpoint = YouTubeEndpoint.videos(apiKey: key, ids: ids)

        let response = try await client.send(endpoint, as: YouTubeVideosResponseDTO.self)

        // Xây map id → DTO để trộn thông tin.
        let statsMap = Dictionary(
            uniqueKeysWithValues: (response.items ?? []).compactMap { item -> (String, YouTubeVideoItemDTO)? in
                guard let id = item.id else { return nil }
                return (id, item)
            }
        )

        return videos.map { video in
            guard let item = statsMap[video.id] else { return video }
            return MusicVideoMapper.mergingStatistics(from: item, into: video)
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
