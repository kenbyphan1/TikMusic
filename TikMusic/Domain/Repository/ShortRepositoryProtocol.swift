import Foundation

/// Giao thức kho chứa dữ liệu Short (video dọc kiểu TikTok).
///
/// Domain layer chỉ biết tới giao thức này — nguồn dữ liệu (YouTube API,
/// Firebase, local...) do tầng Data quyết định và có thể thay đổi mà không
/// ảnh hưởng tới tầng Presentation.
protocol ShortRepositoryProtocol: Sendable {
    /// Lấy danh sách Short đang thịnh hành.
    ///
    /// - Parameter pageToken: token trang tiếp theo (nil nếu là trang đầu).
    /// - Returns: một trang Short.
    func fetchTrendingShorts(pageToken: String?) async throws -> ShortVideoPage

    /// Lấy danh sách Short mới nhất.
    func fetchNewestShorts(pageToken: String?) async throws -> ShortVideoPage

    /// Lấy Short theo tag.
    ///
    /// - Parameters:
    ///   - tag: tag cần tìm.
    ///   - pageToken: token trang tiếp theo.
    func fetchByTag(_ tag: String, pageToken: String?) async throws -> ShortVideoPage

    /// Tìm kiếm Short theo từ khoá (artist/title/tag).
    ///
    /// - Parameters:
    ///   - query: từ khoá tìm kiếm.
    ///   - pageToken: token trang tiếp theo.
    func searchShorts(query: String, pageToken: String?) async throws -> ShortVideoPage

    /// Tải trước trang tiếp theo để feed phát mượt khi cuộn nhanh.
    ///
    /// - Parameter pageToken: token trang kế tiếp (nil nếu chưa có).
    func prefetchNext(pageToken: String?) async throws -> ShortVideoPage

    /// Lọc ra những video có thể nhúng (embeddable) từ danh sách ID.
    ///
    /// - Parameter ids: danh sách ID video cần kiểm tra.
    /// - Returns: danh sách ID video embeddable được.
    func filterEmbeddable(ids: [String]) async throws -> [String]

    /// Cache dữ liệu metadata + thumbnail của Short xuống đĩa (offline).
    ///
    /// - Parameter videos: danh sách Short cần cache.
    func cacheVideos(_ videos: [ShortVideo]) async throws

    /// Đọc lại Short đã cache (dùng khi mất mạng).
    func loadCachedVideos() async throws -> [ShortVideo]
}
