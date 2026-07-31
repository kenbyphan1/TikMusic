import Foundation

/// Dữ liệu mẫu dùng trong SwiftUI Preview.
enum PreviewData {

    /// Store JSON trong bộ nhớ (dùng cho preview — không ghi ra đĩa).
    @MainActor
    static var previewPlaylistRepository: FilePlaylistRepository {
        FilePlaylistRepository(store: JSONFileStore(inMemory: "preview-playlists.json"))
    }

    @MainActor
    static var previewFavoritesRepository: FileFavoritesRepository {
        FileFavoritesRepository(store: JSONFileStore(inMemory: "preview-favorites.json"))
    }

    /// Một vài video mẫu để xem trước giao diện.
    static let videos: [MusicVideo] = [
        MusicVideo(
            id: "video-1",
            title: "Phonk Music Mix 2026 - Best Phonk Playlist",
            channelTitle: "Phonk Nation",
            publishedAt: Date().addingTimeInterval(-86_400),
            description: "Tuyển tập phonk hay nhất.",
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/example1/hqdefault.jpg"),
            viewCount: 1_234_567,
            likeCount: 45_678,
            duration: 3 * 60 + 45,
            category: .phonk
        ),
        MusicVideo(
            id: "video-2",
            title: "Chill Lofi Beats To Relax",
            channelTitle: "Lofi Girl Vibes",
            publishedAt: Date().addingTimeInterval(-172_800),
            description: "Nhạc lofi thư giãn.",
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/example2/hqdefault.jpg"),
            viewCount: 987_654,
            likeCount: 12_345,
            duration: 2 * 60 + 15,
            category: .lofi
        ),
        MusicVideo(
            id: "video-3",
            title: "Nightcore - Famous Songs Remixed",
            channelTitle: "Nightcore FM",
            publishedAt: Date().addingTimeInterval(-259_200),
            description: "Remix nightcore.",
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/example3/hqdefault.jpg"),
            viewCount: 5_678_901,
            likeCount: 234_567,
            duration: 4 * 60 + 2,
            category: .nightcore
        ),
    ]
}
