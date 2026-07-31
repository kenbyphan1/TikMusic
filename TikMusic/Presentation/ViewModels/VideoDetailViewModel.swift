import Foundation
import Observation

/// ViewModel cho màn hình Chi tiết video.
///
/// Chịu trách nhiệm:
/// - Tải chi tiết đầy đủ (thống kê, thời lượng) từ API.
/// - Trạng thái yêu thích + thao tác bật/tắt yêu thích.
/// - Danh sách playlist để thêm video.
@Observable
@MainActor
final class VideoDetailViewModel {

    /// Video gốc được mở (dữ liệu nhanh từ danh sách).
    let video: MusicVideo

    // MARK: - State

    /// Video chi tiết đầy đủ (nil khi chưa tải xong).
    private(set) var detailedVideo: MusicVideo?

    /// Video hiển thị: ưu tiên chi tiết nếu có.
    var displayVideo: MusicVideo { detailedVideo ?? video }

    /// Có nằm trong danh sách yêu thích không.
    private(set) var isFavorite = false

    /// Danh sách playlist hiện có.
    private(set) var playlists: [Playlist] = []

    /// Đang tải chi tiết.
    private(set) var isLoadingDetail = false

    /// Lỗi khi tải chi tiết.
    private(set) var detailError: String?

    /// Thông báo sau khi thêm vào playlist (nil = không hiển thị).
    private(set) var playlistMessage: String?

    // MARK: - Dependencies

    private let videoRepository: VideoRepositoryProtocol
    private let favoritesUseCase: FavoritesUseCase
    private let playlistUseCase: PlaylistUseCase

    /// Khởi tạo ViewModel.
    init(
        video: MusicVideo,
        videoRepository: VideoRepositoryProtocol,
        favoritesUseCase: FavoritesUseCase,
        playlistUseCase: PlaylistUseCase
    ) {
        self.video = video
        self.videoRepository = videoRepository
        self.favoritesUseCase = favoritesUseCase
        self.playlistUseCase = playlistUseCase
    }

    // MARK: - Public API

    /// Tải dữ liệu ban đầu: trạng thái yêu thích, playlist, chi tiết video.
    func load() async {
        checkFavorite()
        loadPlaylists()
        await loadDetail()
    }

    /// Tải chi tiết video từ API.
    func loadDetail() async {
        guard detailedVideo == nil else { return }

        isLoadingDetail = true
        defer { isLoadingDetail = false }

        do {
            let detail = try await videoRepository.fetchVideoDetail(videoID: video.id)
            guard !Task.isCancelled else { return }
            detailedVideo = detail
        } catch {
            guard !Task.isCancelled else { return }
            detailError = error.localizedDescription
        }
    }

    /// Bật/tắt trạng thái yêu thích.
    func toggleFavorite() {
        do {
            if isFavorite {
                try favoritesUseCase.remove(videoID: video.id)
                isFavorite = false
            } else {
                try favoritesUseCase.add(video)
                isFavorite = true
            }
        } catch {
            AppLogger.error("Lỗi thao tác yêu thích: \(error.localizedDescription)")
        }
    }

    /// Tải danh sách playlist.
    func loadPlaylists() {
        playlists = (try? playlistUseCase.fetchAll()) ?? []
    }

    /// Thêm video vào một playlist.
    ///
    /// - Parameter playlistID: id playlist đích.
    /// - Returns: `true` nếu thêm thành công.
    @discardableResult
    func addToPlaylist(_ playlistID: UUID) -> Bool {
        do {
            try playlistUseCase.add(video, to: playlistID)
            playlistMessage = "Đã thêm vào playlist"
            return true
        } catch {
            playlistMessage = "Không thể thêm vào playlist"
            return false
        }
    }

    /// Tạo playlist mới rồi tải lại danh sách.
    func createPlaylist(name: String) {
        do {
            try playlistUseCase.create(name: name)
            loadPlaylists()
        } catch {
            playlistMessage = "Không thể tạo playlist"
        }
    }

    /// Xoá thông báo sau khi đã hiển thị.
    func clearPlaylistMessage() {
        playlistMessage = nil
    }

    // MARK: - Private

    /// Kiểm tra trạng thái yêu thích ban đầu.
    private func checkFavorite() {
        isFavorite = (try? favoritesUseCase.isFavorite(videoID: video.id)) ?? false
    }
}
