import Foundation

/// Giao thức kho chứa playlist lưu trữ cục bộ.
protocol PlaylistRepositoryProtocol: Sendable {
    /// Lấy toàn bộ playlist, sắp theo thời gian tạo (mới nhất trước).
    func fetchPlaylists() throws -> [Playlist]

    /// Tạo playlist mới.
    func createPlaylist(name: String) throws -> Playlist

    /// Đổi tên playlist.
    func renamePlaylist(id: UUID, to newName: String) throws

    /// Xoá playlist.
    func deletePlaylist(id: UUID) throws

    /// Thêm một video vào playlist.
    func addVideo(_ video: MusicVideo, toPlaylist id: UUID) throws

    /// Xoá một video khỏi playlist.
    func removeVideo(videoID: String, fromPlaylist id: UUID) throws

    /// Sắp xếp lại thứ tự video trong playlist.
    func setVideoOrder(_ videoIDs: [String], inPlaylist id: UUID) throws
}
