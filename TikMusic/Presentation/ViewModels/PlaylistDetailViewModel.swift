import Foundation
import Observation
import SwiftUI

/// ViewModel cho màn hình chi tiết một playlist.
///
/// Chịu trách nhiệm:
/// - Hiển thị các video trong playlist.
/// - Tìm kiếm trong playlist.
/// - Kéo thả sắp xếp thứ tự video.
/// - Xoá video khỏi playlist.
/// - Đổi tên playlist.
@Observable
@MainActor
final class PlaylistDetailViewModel {

    // MARK: - State

    /// ID playlist đang xem.
    let playlistID: UUID

    /// Tên playlist (có thể chỉnh sửa).
    private(set) var playlistName: String

    /// Toàn bộ video trong playlist (theo thứ tự người dùng sắp xếp).
    private(set) var allVideos: [MusicVideo]

    /// Từ khoá tìm kiếm trong playlist.
    var searchText = ""

    // MARK: - Dependencies

    private let playlistUseCase: PlaylistUseCase

    /// Khởi tạo ViewModel.
    init(playlist: Playlist, playlistUseCase: PlaylistUseCase) {
        self.playlistID = playlist.id
        self.playlistName = playlist.name
        self.allVideos = playlist.videos
        self.playlistUseCase = playlistUseCase
    }

    // MARK: - Public API

    /// Video sau khi lọc theo từ khoá.
    var filteredVideos: [MusicVideo] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allVideos }
        return allVideos.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.channelTitle.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Có đang tìm kiếm (khi đó tắt tính năng kéo thả).
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Binding cho tên playlist (dùng trong TextField đổi tên).
    var playlistNameBinding: Binding<String> {
        Binding(
            get: { playlistName },
            set: { updateName($0) }
        )
    }

    /// Cập nhật tên playlist (lưu khi khác tên cũ).
    func updateName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != playlistName else { return }
        playlistName = trimmed
        try? playlistUseCase.rename(id: playlistID, to: trimmed)
    }

    /// Sắp xếp lại video (drag & drop).
    func move(from source: IndexSet, to destination: Int) {
        allVideos.move(fromOffsets: source, toOffset: destination)
        try? playlistUseCase.setOrder(allVideos.map(\.id), in: playlistID)
    }

    /// Xoá một video khỏi playlist.
    func remove(_ video: MusicVideo) {
        allVideos.removeAll { $0.id == video.id }
        try? playlistUseCase.remove(videoID: video.id, from: playlistID)
    }
}
