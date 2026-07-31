import Foundation

/// Một video nhạc thuộc Domain layer.
///
/// Đây là model trung gian mà toàn bộ ứng dụng (UI, UseCase, Repository)
/// sử dụng — độc lập hoàn toàn với DTO của YouTube.
struct MusicVideo: Identifiable, Hashable, Sendable {
    /// ID video trên YouTube.
    let id: String

    /// Tiêu đề video.
    let title: String

    /// ID kênh đăng tải.
    let channelID: String

    /// Tên kênh đăng tải.
    let channelTitle: String

    /// Thời gian đăng tải.
    let publishedAt: Date?

    /// Mô tả video.
    let description: String

    /// URL thumbnail chuẩn (độ phân giải trung bình).
    let thumbnailURL: URL?

    /// URL thumbnail độ phân giải cao (dùng cho màn hình chi tiết).
    let thumbnailHighURL: URL?

    /// Lượt xem (nếu có).
    let viewCount: Int?

    /// Lượt thích (nếu có).
    let likeCount: Int?

    /// Thời lượng video tính bằng giây (nếu có).
    let duration: TimeInterval?

    /// Chủ đề nhạc mà video thuộc về (nil khi là kết quả tìm kiếm tự do).
    let category: MusicCategory?

    /// URL mở video trong trình duyệt.
    var url: URL {
        URL(string: "https://www.youtube.com/watch?v=\(id)")!
    }

    /// URL chia sẻ (giống url).
    var shareURL: URL { url }

    /// URL nhúng video để phát trong web view.
    var embedURL: URL {
        URL(string: "https://www.youtube.com/embed/\(id)?playsinline=1")!
    }

    /// Khởi tạo đầy đủ (dùng trong mapper, test, preview).
    init(
        id: String,
        title: String,
        channelID: String = "",
        channelTitle: String,
        publishedAt: Date? = nil,
        description: String = "",
        thumbnailURL: URL? = nil,
        thumbnailHighURL: URL? = nil,
        viewCount: Int? = nil,
        likeCount: Int? = nil,
        duration: TimeInterval? = nil,
        category: MusicCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.channelID = channelID
        self.channelTitle = channelTitle
        self.publishedAt = publishedAt
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.thumbnailHighURL = thumbnailHighURL
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.duration = duration
        self.category = category
    }
}

/// Một trang kết quả video, kèm token phân trang cho lần tải tiếp theo.
struct VideoPage: Sendable {
    let videos: [MusicVideo]
    let nextPageToken: String?

    /// Trang rỗng (dùng cho state ban đầu / test).
    static let empty = VideoPage(videos: [], nextPageToken: nil)
}
