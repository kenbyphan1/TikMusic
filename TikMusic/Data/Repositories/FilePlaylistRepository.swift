import Foundation

/// Repository playlist lưu trữ trên đĩa bằng JSON (thay thế SwiftData).
///
/// Không phụ thuộc SwiftData — tránh crash runtime trên một số phiên bản
/// iOS. Mọi thao tác đều đồng bộ trên main thread (dữ liệu nhỏ).
@MainActor
final class FilePlaylistRepository: PlaylistRepositoryProtocol {

    /// Store JSON dùng chung cho dữ liệu playlist.
    private let store: JSONFileStore

    /// Khởi tạo repository.
    init() {
        store = JSONFileStore(fileName: "playlists.json")
    }

    /// Khởi tạo với store cụ thể (dùng cho preview/test).
    init(store: JSONFileStore) {
        self.store = store
    }

    // MARK: - PlaylistRepositoryProtocol

    /// Lấy toàn bộ playlist, mới nhất trước.
    func fetchPlaylists() throws -> [Playlist] {
        let playlists = try store.load([Playlist].self) ?? []
        return playlists.sorted { $0.createdAt > $1.createdAt }
    }

    /// Tạo playlist mới.
    func createPlaylist(name: String) throws -> Playlist {
        var playlists = try store.load([Playlist].self) ?? []
        let playlist = Playlist(
            id: UUID(),
            name: name,
            createdAt: Date(),
            videos: []
        )
        playlists.append(playlist)
        try store.save(playlists)
        return playlist
    }

    /// Đổi tên playlist.
    func renamePlaylist(id: UUID, to newName: String) throws {
        var playlists = try store.load([Playlist].self) ?? []
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[index].name = newName
        try store.save(playlists)
    }

    /// Xoá playlist.
    func deletePlaylist(id: UUID) throws {
        var playlists = try store.load([Playlist].self) ?? []
        playlists.removeAll { $0.id == id }
        try store.save(playlists)
    }

    /// Thêm video vào playlist (bỏ qua nếu video đã tồn tại).
    func addVideo(_ video: MusicVideo, toPlaylist id: UUID) throws {
        var playlists = try store.load([Playlist].self) ?? []
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }

        // Tránh thêm trùng video.
        if playlists[index].videos.contains(where: { $0.id == video.id }) {
            return
        }

        playlists[index].videos.append(video)
        try store.save(playlists)
    }

    /// Xoá một video khỏi playlist.
    func removeVideo(videoID: String, fromPlaylist id: UUID) throws {
        var playlists = try store.load([Playlist].self) ?? []
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[index].videos.removeAll { $0.id == videoID }
        try store.save(playlists)
    }

    /// Sắp xếp lại thứ tự video theo danh sách ID cung cấp.
    func setVideoOrder(_ videoIDs: [String], inPlaylist id: UUID) throws {
        var playlists = try store.load([Playlist].self) ?? []
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }

        // Xây map videoID → video để sắp xếp lại đúng thứ tự mới.
        let videoMap = Dictionary(uniqueKeysWithValues: playlists[index].videos.map { ($0.id, $0) })

        // Giữ các video không nằm trong danh sách (nếu có) ở cuối.
        let ordered = videoIDs.compactMap { videoMap[$0] }
        let rest = playlists[index].videos.filter { !videoIDs.contains($0.id) }

        playlists[index].videos = ordered + rest
        try store.save(playlists)
    }
}
