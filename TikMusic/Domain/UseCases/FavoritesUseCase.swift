import Foundation

/// UseCase quản lý danh sách video yêu thích.
struct FavoritesUseCase {
    private let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    func fetchAll() throws -> [MusicVideo] {
        try repository.fetchFavorites()
    }

    func isFavorite(videoID: String) throws -> Bool {
        try repository.isFavorite(videoID: videoID)
    }

    func add(_ video: MusicVideo) throws {
        try repository.addFavorite(video)
    }

    func remove(videoID: String) throws {
        try repository.removeFavorite(videoID: videoID)
    }

    func removeAll() throws {
        try repository.removeAllFavorites()
    }
}
