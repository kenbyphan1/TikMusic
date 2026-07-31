import Foundation
import SwiftData

/// Repository danh sách yêu thích lưu trữ cục bộ bằng SwiftData.
@MainActor
final class SwiftDataFavoritesRepository: FavoritesRepositoryProtocol {

    /// Context SwiftData dùng để đọc/ghi.
    private let context: ModelContext

    /// Khởi tạo repository.
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - FavoritesRepositoryProtocol

    /// Lấy toàn bộ video yêu thích, mới thêm trước.
    func fetchFavorites() throws -> [MusicVideo] {
        let descriptor = FetchDescriptor<FavoriteVideoRecord>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let records = try context.fetch(descriptor)
        return records.map(Self.mapToDomain)
    }

    /// Kiểm tra video có trong danh sách yêu thích hay không.
    func isFavorite(videoID: String) throws -> Bool {
        try favoriteRecord(videoID: videoID) != nil
    }

    /// Thêm video vào danh sách yêu thích (bỏ qua nếu đã tồn tại).
    func addFavorite(_ video: MusicVideo) throws {
        // Nếu đã tồn tại (đúng theo constraint unique) thì không làm gì.
        if try favoriteRecord(videoID: video.id) != nil {
            return
        }

        let record = FavoriteVideoRecord(
            videoID: video.id,
            title: video.title,
            channelTitle: video.channelTitle,
            thumbnailURLString: video.thumbnailURL?.absoluteString,
            viewCount: video.viewCount ?? 0,
            publishedAt: video.publishedAt
        )
        context.insert(record)
        try context.save()
    }

    /// Xoá video khỏi danh sách yêu thích.
    func removeFavorite(videoID: String) throws {
        guard let record = try favoriteRecord(videoID: videoID) else { return }
        context.delete(record)
        try context.save()
    }

    /// Xoá toàn bộ danh sách yêu thích.
    func removeAllFavorites() throws {
        let descriptor = FetchDescriptor<FavoriteVideoRecord>()
        let records = try context.fetch(descriptor)
        for record in records {
            context.delete(record)
        }
        try context.save()
    }

    // MARK: - Private

    /// Tìm `FavoriteVideoRecord` theo videoID.
    private func favoriteRecord(videoID: String) throws -> FavoriteVideoRecord? {
        let predicate = #Predicate<FavoriteVideoRecord> { $0.videoID == videoID }
        var descriptor = FetchDescriptor<FavoriteVideoRecord>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Chuyển `FavoriteVideoRecord` sang `MusicVideo` domain.
    private static func mapToDomain(_ record: FavoriteVideoRecord) -> MusicVideo {
        MusicVideo(
            id: record.videoID,
            title: record.title,
            channelID: "",
            channelTitle: record.channelTitle,
            publishedAt: record.publishedAt,
            thumbnailURL: record.thumbnailURLString.flatMap(URL.init(string:)),
            viewCount: record.viewCount > 0 ? record.viewCount : nil
        )
    }
}
