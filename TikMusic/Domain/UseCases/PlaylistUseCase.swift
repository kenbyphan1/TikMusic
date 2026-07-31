import Foundation

/// UseCase quản lý playlist cá nhân.
///
/// Tập hợp các thao tác nghiệp vụ liên quan playlist thành một chỗ,
/// tránh Presentation phải tuỳ tiện gọi repository.
struct PlaylistUseCase {
    private let repository: PlaylistRepositoryProtocol

    init(repository: PlaylistRepositoryProtocol) {
        self.repository = repository
    }

    func fetchAll() throws -> [Playlist] {
        try repository.fetchPlaylists()
    }

    func create(name: String) throws -> Playlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return try repository.createPlaylist(name: trimmed.isEmpty ? "Playlist mới" : trimmed)
    }

    func rename(id: UUID, to name: String) throws {
        try repository.renamePlaylist(id: id, to: name)
    }

    func delete(id: UUID) throws {
        try repository.deletePlaylist(id: id)
    }

    func add(_ video: MusicVideo, to id: UUID) throws {
        try repository.addVideo(video, toPlaylist: id)
    }

    func remove(videoID: String, from id: UUID) throws {
        try repository.removeVideo(videoID: videoID, fromPlaylist: id)
    }

    func setOrder(_ videoIDs: [String], in id: UUID) throws {
        try repository.setVideoOrder(videoIDs, inPlaylist: id)
    }
}
