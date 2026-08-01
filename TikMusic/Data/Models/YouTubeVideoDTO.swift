import Foundation

// MARK: - Response của /youtube/v3/search

/// Response chuẩn của endpoint search.
struct YouTubeSearchResponseDTO: Decodable {
    let kind: String?
    let etag: String?
    let nextPageToken: String?
    let regionCode: String?
    let pageInfo: YouTubePageInfoDTO?
    let items: [YouTubeSearchItemDTO]?
}

/// Thông tin phân trang trả về từ API.
struct YouTubePageInfoDTO: Decodable {
    let totalResults: Int?
    let resultsPerPage: Int?
}

/// Một phần tử trong kết quả search.
struct YouTubeSearchItemDTO: Decodable {
    let kind: String?
    let etag: String?
    let id: YouTubeResourceIDDTO?
    let snippet: YouTubeSnippetDTO?
}

/// ID của resource trả về từ search (có thể là video/channel/playlist).
struct YouTubeResourceIDDTO: Decodable {
    let kind: String?
    let videoId: String?
    let channelId: String?
    let playlistId: String?
}

// MARK: - Snippet (dùng chung)

/// Snippet chứa thông tin mô tả của một resource.
struct YouTubeSnippetDTO: Decodable {
    let publishedAt: String?
    let channelId: String?
    let title: String?
    let description: String?
    let thumbnails: YouTubeThumbnailsDTO?
    let channelTitle: String?
    let liveBroadcastContent: String?
    let publishTime: String?
}

/// Bộ thumbnail ở nhiều độ phân giải.
struct YouTubeThumbnailsDTO: Decodable {
    let `default`: YouTubeThumbnailDTO?
    let medium: YouTubeThumbnailDTO?
    let high: YouTubeThumbnailDTO?
    let standard: YouTubeThumbnailDTO?
    let maxres: YouTubeThumbnailDTO?
}

/// Một thumbnail với URL và kích thước.
struct YouTubeThumbnailDTO: Decodable {
    let url: String?
    let width: Int?
    let height: Int?
}

// MARK: - Response của /youtube/v3/videos

/// Response của endpoint lấy chi tiết video.
struct YouTubeVideosResponseDTO: Decodable {
    let kind: String?
    let etag: String?
    let nextPageToken: String?
    let pageInfo: YouTubePageInfoDTO?
    let items: [YouTubeVideoItemDTO]?
}

/// Một video đầy đủ thông tin (snippet + contentDetails + statistics).
struct YouTubeVideoItemDTO: Decodable {
    let kind: String?
    let etag: String?
    let id: String?
    let snippet: YouTubeSnippetDTO?
    let contentDetails: YouTubeContentDetailsDTO?
    let statistics: YouTubeStatisticsDTO?
    let status: YouTubeStatusDTO?
}

/// Trạng thái video (`part=status`) — dùng để biết video có embeddable không.
struct YouTubeStatusDTO: Decodable {
    let uploadStatus: String?
    let privacyStatus: String?
    let license: String?
    let embeddable: Bool?
    let publicStatsViewable: Bool?
    let madeForKids: Bool?
}

/// Thông tin chi tiết nội dung video (thời lượng ISO 8601).
struct YouTubeContentDetailsDTO: Decodable {
    let duration: String?
    let dimension: String?
    let definition: String?
    let caption: String?
    let licensedContent: Bool?
}

/// Thống kê của video.
struct YouTubeStatisticsDTO: Decodable {
    let viewCount: String?
    let likeCount: String?
    let favoriteCount: String?
    let commentCount: String?
}

// MARK: - Response lỗi chuẩn của Google

/// Cấu trúc lỗi chuẩn mà Google API trả về khi request thất bại.
struct YouTubeErrorResponseDTO: Decodable {
    let error: YouTubeErrorDTO?
}

struct YouTubeErrorDTO: Decodable {
    let code: Int?
    let message: String?
    let errors: [YouTubeErrorDetailDTO]?
}

struct YouTubeErrorDetailDTO: Decodable {
    let message: String?
    let domain: String?
    let reason: String?
}
