import Foundation
import Observation

/// ViewModel cho danh sách playlist.
///
/// Chịu trách nhiệm: hiển thị, tạo, đổi tên, xoá playlist.
@Observable
@MainActor
final class PlaylistListViewModel {

    // MARK: - State

    /// Danh sách playlist.
    private(set) var playlists: [Playlist] = []

    /// Có đang hiện sheet tạo playlist không.
    var isShowingCreateSheet = false

    /// Tên playlist mới người dùng nhập.
    var newPlaylistName = ""

    // MARK: - Dependencies

    private let playlistUseCase: PlaylistUseCase

    /// Khởi tạo ViewModel.
    init(playlistUseCase: PlaylistUseCase) {
        self.playlistUseCase = playlistUseCase
    }

    // MARK: - Public API

    /// Tải danh sách playlist.
    func load() {
        playlists = (try? playlistUseCase.fetchAll()) ?? []
    }

    /// Tạo playlist mới từ `newPlaylistName`.
    func createPlaylist() {
        let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try playlistUseCase.create(name: trimmed)
            newPlaylistName = ""
            isShowingCreateSheet = false
            load()
        } catch {
            AppLogger.error("Tạo playlist thất bại: \(error.localizedDescription)")
        }
    }

    /// Đổi tên playlist.
    func rename(_ playlist: Playlist, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try playlistUseCase.rename(id: playlist.id, to: trimmed)
            load()
        } catch {
            AppLogger.error("Đổi tên playlist thất bại: \(error.localizedDescription)")
        }
    }

    /// Xoá playlist.
    func delete(_ playlist: Playlist) {
        do {
            try playlistUseCase.delete(id: playlist.id)
            load()
        } catch {
            AppLogger.error("Xoá playlist thất bại: \(error.localizedDescription)")
        }
    }
}
