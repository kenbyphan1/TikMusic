import Foundation

/// Giao thức kho chứa dữ liệu video từ xa (YouTube Data API).
///
/// Domain layer chỉ biết tới giao thức này — việc lấy dữ liệu từ đâu
/// (API thật, mock, cache...) do tầng Data quyết định.
protocol VideoRepositoryProtocol: Sendable {
    /// Lấy video theo chủ đề với phân trang.
    ///
    /// - Parameters:
    ///   - category: chủ đề nhạc.
    ///   - pageToken: token trang tiếp theo (nil nếu là trang đầu).
    /// - Returns: một trang video.
    func fetchVideos(category: MusicCategory, pageToken: String?) async throws -> VideoPage

    /// Tìm kiếm video nhạc theo từ khoá.
    ///
    /// - Parameters:
    ///   - query: từ khoá tìm kiếm.
    ///   - pageToken: token trang tiếp theo (nil nếu là trang đầu).
    /// - Returns: một trang video.
    func searchVideos(query: String, pageToken: String?) async throws -> VideoPage

    /// Lấy chi tiết đầy đủ một video (bao gồm thống kê, thời lượng).
    ///
    /// - Parameter videoID: ID video trên YouTube.
    /// - Returns: `MusicVideo` đầy đủ thông tin.
    func fetchVideoDetail(videoID: String) async throws -> MusicVideo
}
