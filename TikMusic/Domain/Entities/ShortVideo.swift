import Foundation

/// Một video ngắn (Short) thuộc Domain layer — độc lập với DTO của YouTube.
///
/// Được dùng cho feed video dọc kiểu TikTok trong tab Short. Dữ liệu có thể
/// đến từ nhiều nguồn (remote/firebase/local) — phân biệt qua `source`.
struct ShortVideo: Identifiable, Hashable, Codable, Sendable {
    /// ID video.
    let id: String

    /// Tiêu đề.
    let title: String

    /// Nghệ sĩ / kênh đăng tải.
    let artist: String

    /// URL thumbnail (dùng để preload + cache offline).
    let thumbnailURL: URL?

    /// URL video.
    let videoURL: URL

    /// Thời lượng (giây).
    let duration: TimeInterval?

    /// Lượt thích.
    let likes: Int?

    /// Lượt xem.
    let views: Int?

    /// Lượt bình luận.
    let comments: Int?

    /// Lượt chia sẻ.
    let shareCount: Int?

    /// Thời điểm đăng.
    let createdAt: Date?

    /// Các tag liên quan.
    let tags: [String]

    /// Nguồn dữ liệu.
    let source: ShortSource

    /// Video rỗng (dùng cho state khởi tạo).
    static let empty = ShortVideo(
        id: "",
        title: "",
        artist: "",
        thumbnailURL: nil,
        videoURL: URL(string: "https://www.youtube.com/")!,
        duration: nil,
        likes: nil,
        views: nil,
        comments: nil,
        shareCount: nil,
        createdAt: nil,
        tags: [],
        source: .local
    )

    /// URL mở video trong trình duyệt.
    var url: URL {
        URL(string: "https://www.youtube.com/watch?v=\(id)")!
    }

    /// URL chia sẻ.
    var shareURL: URL { url }

    /// URL nhúng để phát trong web view.
    var embedURL: URL {
        URL(string: "https://www.youtube.com/embed/\(id)?playsinline=1")!
    }

    /// Khởi tạo đầy đủ.
    init(
        id: String,
        title: String,
        artist: String,
        thumbnailURL: URL? = nil,
        videoURL: URL,
        duration: TimeInterval? = nil,
        likes: Int? = nil,
        views: Int? = nil,
        comments: Int? = nil,
        shareCount: Int? = nil,
        createdAt: Date? = nil,
        tags: [String] = [],
        source: ShortSource = .remote
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.duration = duration
        self.likes = likes
        self.views = views
        self.comments = comments
        self.shareCount = shareCount
        self.createdAt = createdAt
        self.tags = tags
        self.source = source
    }

    /// Chuyển thành `MusicVideo` để dùng chung yêu thích/playlist.
    var asMusicVideo: MusicVideo {
        MusicVideo(
            id: id,
            title: title,
            channelTitle: artist,
            publishedAt: createdAt,
            description: "",
            thumbnailURL: thumbnailURL,
            thumbnailHighURL: thumbnailURL,
            viewCount: views,
            likeCount: likes,
            duration: duration,
            category: nil
        )
    }
}

/// Nguồn dữ liệu của Short.
enum ShortSource: String, Codable, Sendable {
    /// Nguồn từ xa (API).
    case remote

    /// Nguồn Firebase (tuỳ chọn).
    case firebase

    /// Dữ liệu mẫu / cục bộ.
    case local
}

/// Một trang kết quả Short, kèm token phân trang.
struct ShortVideoPage: Sendable {
    let videos: [ShortVideo]
    let nextPageToken: String?

    /// Trang rỗng.
    static let empty = ShortVideoPage(videos: [], nextPageToken: nil)
}
