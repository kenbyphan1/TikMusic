import Foundation
import Observation

/// Container tiêm phụ thuộc (Dependency Injection) cho toàn bộ ứng dụng.
///
/// Tạo một lần duy nhất tại `TikMusicApp`, được đưa vào SwiftUI Environment
/// để mọi view/ViewModel truy cập. Đây là Composition Root theo Clean Architecture:
/// - Tầng Core (APIClient, caches) được dựng sẵn.
/// - Tầng Data (repositories) được gắn vào tầng Domain (use cases).
/// - Tầng Presentation (ViewModels) dùng use cases.
@Observable
@MainActor
final class DependencyContainer {

    // MARK: - Services

    /// Quản lý API Key (build-time + runtime trong Keychain).
    let apiKeyProvider: APIKeyProvider

    /// Quản lý chủ đề giao diện (Dark/Light/System).
    let colorSchemeManager: ColorSchemeManager

    /// Lịch sử tìm kiếm cục bộ.
    let searchHistoryStore: SearchHistoryStore

    /// Cache video thay thế (Smart Fallback).
    let playbackCacheStore: PlaybackCacheStore

    /// Lịch sử xem Short (gần đây + tiếp tục xem).
    let shortHistoryStore: ShortHistoryStore

    /// Cache metadata Short offline.
    let shortCacheStore: ShortCacheStore

    // MARK: - Repositories

    /// Repository video từ YouTube Data API.
    let videoRepository: VideoRepositoryProtocol

    /// Repository Short (video dọc) từ YouTube Data API.
    let shortRepository: ShortRepositoryProtocol

    /// Repository playlist cục bộ (file JSON).
    let playlistRepository: PlaylistRepositoryProtocol

    /// Repository yêu thích cục bộ (file JSON).
    let favoritesRepository: FavoritesRepositoryProtocol

    // MARK: - Use cases

    let fetchVideosUseCase: FetchVideosUseCase
    let searchVideosUseCase: SearchVideosUseCase
    let playlistUseCase: PlaylistUseCase
    let favoritesUseCase: FavoritesUseCase
    let videoFallbackUseCase: VideoFallbackUseCase
    let shortsUseCase: ShortsUseCase

    // MARK: - ViewModels dùng chung (giữ state xuyên các tab)

    let homeViewModel: HomeViewModel
    let searchViewModel: SearchViewModel
    let playlistListViewModel: PlaylistListViewModel
    let favoritesViewModel: FavoritesViewModel
    let settingsViewModel: SettingsViewModel
    let shortsViewModel: ShortsViewModel

    /// Khởi tạo toàn bộ đồ thị phụ thuộc.
    init() {
        // Services
        let apiKeyProvider = APIKeyProvider()
        let colorSchemeManager = ColorSchemeManager()
        let searchHistoryStore = SearchHistoryStore()
        let playbackCacheStore = PlaybackCacheStore(store: JSONFileStore(fileName: "playback-cache.json"))
        let shortHistoryStore = ShortHistoryStore(store: JSONFileStore(fileName: "shorts-history.json"))
        let shortCacheStore = ShortCacheStore(store: JSONFileStore(fileName: "shorts-cache.json"))

        // Networking
        let apiClient = APIClient(session: URLSession.shared)

        // Repositories
        let videoRepository = YouTubeVideoRepository(client: apiClient, apiKeyProvider: apiKeyProvider)
        let shortRepository = YouTubeShortRepository(
            client: apiClient,
            apiKeyProvider: apiKeyProvider,
            cacheStore: shortCacheStore
        )
        let playlistRepository = FilePlaylistRepository()
        let favoritesRepository = FileFavoritesRepository()

        // Use cases
        let fetchVideosUseCase = FetchVideosUseCase(repository: videoRepository)
        let searchVideosUseCase = SearchVideosUseCase(repository: videoRepository)
        let playlistUseCase = PlaylistUseCase(repository: playlistRepository)
        let favoritesUseCase = FavoritesUseCase(repository: favoritesRepository)
        let videoFallbackUseCase = VideoFallbackUseCase(
            repository: videoRepository,
            cacheStore: playbackCacheStore
        )
        let shortsUseCase = ShortsUseCase(repository: shortRepository)

        // ViewModels
        let homeViewModel = HomeViewModel(
            fetchVideosUseCase: fetchVideosUseCase,
            apiKeyProvider: apiKeyProvider
        )
        let searchViewModel = SearchViewModel(
            searchVideosUseCase: searchVideosUseCase,
            searchHistoryStore: searchHistoryStore,
            apiKeyProvider: apiKeyProvider
        )
        let playlistListViewModel = PlaylistListViewModel(playlistUseCase: playlistUseCase)
        let favoritesViewModel = FavoritesViewModel(favoritesUseCase: favoritesUseCase)
        let settingsViewModel = SettingsViewModel(
            colorSchemeManager: colorSchemeManager,
            apiKeyProvider: apiKeyProvider
        )
        let shortsViewModel = ShortsViewModel(
            shortsUseCase: shortsUseCase,
            favoritesUseCase: favoritesUseCase,
            historyStore: shortHistoryStore,
            apiKeyProvider: apiKeyProvider
        )

        // Gán vào stored properties
        self.apiKeyProvider = apiKeyProvider
        self.colorSchemeManager = colorSchemeManager
        self.searchHistoryStore = searchHistoryStore
        self.playbackCacheStore = playbackCacheStore
        self.shortHistoryStore = shortHistoryStore
        self.shortCacheStore = shortCacheStore
        self.videoRepository = videoRepository
        self.shortRepository = shortRepository
        self.playlistRepository = playlistRepository
        self.favoritesRepository = favoritesRepository
        self.fetchVideosUseCase = fetchVideosUseCase
        self.searchVideosUseCase = searchVideosUseCase
        self.playlistUseCase = playlistUseCase
        self.favoritesUseCase = favoritesUseCase
        self.videoFallbackUseCase = videoFallbackUseCase
        self.shortsUseCase = shortsUseCase
        self.homeViewModel = homeViewModel
        self.searchViewModel = searchViewModel
        self.playlistListViewModel = playlistListViewModel
        self.favoritesViewModel = favoritesViewModel
        self.settingsViewModel = settingsViewModel
        self.shortsViewModel = shortsViewModel
    }

    // MARK: - Factory methods (ViewModel không dùng chung)

    /// Tạo ViewModel cho màn hình chi tiết video (mới mỗi lần mở).
    func makeVideoDetailViewModel(video: MusicVideo) -> VideoDetailViewModel {
        VideoDetailViewModel(
            video: video,
            videoRepository: videoRepository,
            favoritesUseCase: favoritesUseCase,
            playlistUseCase: playlistUseCase,
            fallbackUseCase: videoFallbackUseCase
        )
    }

    /// Tạo ViewModel cho màn hình chi tiết playlist.
    func makePlaylistDetailViewModel(playlist: Playlist) -> PlaylistDetailViewModel {
        PlaylistDetailViewModel(playlist: playlist, playlistUseCase: playlistUseCase)
    }
}
