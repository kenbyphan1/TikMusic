import Foundation

/// Repository danh sách yêu thích lưu trữ trên đĩa bằng JSON (thay thế SwiftData).
///
/// Không phụ thuộc SwiftData — tránh crash runtime trên một số phiên bản
/// iOS. Mọi thao tác đều đồng bộ trên main thread (dữ liệu nhỏ).
@MainActor
final class FileFavoritesRepository: FavoritesRepositoryProtocol {

    /// Store JSON dùng chung cho dữ liệu yêu thích.
    private let store: JSONFileStore

    /// Khởi tạo repository.
    init() {
        store = JSONFileStore(fileName: "favorites.json")
    }

    /// Khởi tạo với store cụ thể (dùng cho preview/test).
    init(store: JSONFileStore) {
        self.store = store
    }

    // MARK: - FavoritesRepositoryProtocol

    /// Lấy toàn bộ video yêu thích, mới thêm trước.
    func fetchFavorites() throws -> [MusicVideo] {
        let favorites = try store.load([MusicVideo].self) ?? []
        return favorites.reversed()
    }

    /// Kiểm tra video có trong danh sách yêu thích hay không.
    func isFavorite(videoID: String) throws -> Bool {
        let favorites = try store.load([MusicVideo].self) ?? []
        return favorites.contains { $0.id == videoID }
    }

    /// Thêm video vào danh sách yêu thích (bỏ qua nếu đã tồn tại).
    func addFavorite(_ video: MusicVideo) throws {
        var favorites = try store.load([MusicVideo].self) ?? []

        // Nếu đã tồn tại thì không làm gì.
        if favorites.contains(where: { $0.id == video.id }) {
            return
        }

        favorites.append(video)
        try store.save(favorites)
    }

    /// Xoá video khỏi danh sách yêu thích.
    func removeFavorite(videoID: String) throws {
        var favorites = try store.load([MusicVideo].self) ?? []
        favorites.removeAll { $0.id == videoID }
        try store.save(favorites)
    }

    /// Xoá toàn bộ danh sách yêu thích.
    func removeAllFavorites() throws {
        try store.clear()
    }
}
