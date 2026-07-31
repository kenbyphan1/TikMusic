import Foundation
import SwiftData

// MARK: - Playlist

/// Model SwiftData lưu một playlist cục bộ.
@Model
final class PlaylistRecord {
    /// ID duy nhất (dùng làm identifier của `Playlist` domain).
    @Attribute(.unique) var id: UUID

    /// Tên playlist.
    var name: String

    /// Thời điểm tạo playlist.
    var createdAt: Date

    /// Danh sách video trong playlist (xoá cascade khi xoá playlist).
    @Relationship(deleteRule: .cascade, inverse: \PlaylistItemRecord.playlist)
    var items: [PlaylistItemRecord]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        items: [PlaylistItemRecord] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.items = items
    }
}

/// Model SwiftData lưu một video bên trong playlist.
@Model
final class PlaylistItemRecord {
    /// ID video trên YouTube.
    var videoID: String

    /// Tiêu đề video.
    var title: String

    /// Tên kênh đăng tải.
    var channelTitle: String

    /// URL thumbnail dạng chuỗi (tránh lưu URL phức tạp).
    var thumbnailURLString: String?

    /// Lượt xem (nếu có).
    var viewCount: Int

    /// Thời điểm thêm vào playlist.
    var addedAt: Date

    /// Playlist chứa video này (ngược với relationship `items`).
    var playlist: PlaylistRecord?

    init(
        videoID: String,
        title: String,
        channelTitle: String,
        thumbnailURLString: String?,
        viewCount: Int,
        addedAt: Date = Date()
    ) {
        self.videoID = videoID
        self.title = title
        self.channelTitle = channelTitle
        self.thumbnailURLString = thumbnailURLString
        self.viewCount = viewCount
        self.addedAt = addedAt
    }
}

// MARK: - Favorites

/// Model SwiftData lưu một video yêu thích.
@Model
final class FavoriteVideoRecord {
    /// ID video trên YouTube (duy nhất — không cho phép trùng).
    @Attribute(.unique) var videoID: String

    /// Tiêu đề video.
    var title: String

    /// Tên kênh đăng tải.
    var channelTitle: String

    /// URL thumbnail dạng chuỗi.
    var thumbnailURLString: String?

    /// Lượt xem (nếu có).
    var viewCount: Int

    /// Thời điểm đăng tải.
    var publishedAt: Date?

    /// Thời điểm thêm vào danh sách yêu thích.
    var addedAt: Date

    init(
        videoID: String,
        title: String,
        channelTitle: String,
        thumbnailURLString: String?,
        viewCount: Int,
        publishedAt: Date?,
        addedAt: Date = Date()
    ) {
        self.videoID = videoID
        self.title = title
        self.channelTitle = channelTitle
        self.thumbnailURLString = thumbnailURLString
        self.viewCount = viewCount
        self.publishedAt = publishedAt
        self.addedAt = addedAt
    }
}
