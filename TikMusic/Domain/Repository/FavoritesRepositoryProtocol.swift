import Foundation

/// Giao thức kho chứa danh sách yêu thích lưu trữ cục bộ.
protocol FavoritesRepositoryProtocol: Sendable {
    /// Lấy toàn bộ video yêu thích.
    func fetchFavorites() throws -> [MusicVideo]

    /// Kiểm tra một video có nằm trong danh sách yêu thích không.
    func isFavorite(videoID: String) throws -> Bool

    /// Thêm video vào danh sách yêu thích (bỏ qua nếu đã tồn tại).
    func addFavorite(_ video: MusicVideo) throws

    /// Xoá video khỏi danh sách yêu thích.
    func removeFavorite(videoID: String) throws

    /// Xoá toàn bộ danh sách yêu thích.
    func removeAllFavorites() throws
}
