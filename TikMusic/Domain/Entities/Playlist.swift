import Foundation

/// Một playlist do người dùng tạo.
struct Playlist: Identifiable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date
    var videos: [MusicVideo]

    /// Số lượng video trong playlist.
    var videoCount: Int { videos.count }
}
