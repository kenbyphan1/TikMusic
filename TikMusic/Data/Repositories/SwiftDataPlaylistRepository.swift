import Foundation
import SwiftData

/// Repository playlist lưu trữ cục bộ bằng SwiftData.
///
/// Mọi thao tác đều thực hiện trên `ModelContext` chính của app
/// (main context), vì vậy repository được đánh dấu `@MainActor`.
@MainActor
final class SwiftDataPlaylistRepository: PlaylistRepositoryProtocol {

    /// Context SwiftData dùng để đọc/ghi.
    private let context: ModelContext

    /// Khởi tạo repository.
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - PlaylistRepositoryProtocol

    /// Lấy toàn bộ playlist, mới nhất trước.
    func fetchPlaylists() throws -> [Playlist] {
        let descriptor = FetchDescriptor<PlaylistRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = try context.fetch(descriptor)
        return records.map(Self.mapToDomain)
    }

    /// Tạo playlist mới.
    func createPlaylist(name: String) throws -> Playlist {
        let record = PlaylistRecord(name: name)
        context.insert(record)
        try context.save()
        return Self.mapToDomain(record)
    }

    /// Đổi tên playlist.
    func renamePlaylist(id: UUID, to newName: String) throws {
        guard let record = try playlistRecord(id: id) else { return }
        record.name = newName
        try context.save()
    }

    /// Xoá playlist (các item bị xoá theo cascade).
    func deletePlaylist(id: UUID) throws {
        guard let record = try playlistRecord(id: id) else { return }
        context.delete(record)
        try context.save()
    }

    /// Thêm video vào playlist (bỏ qua nếu video đã tồn tại).
    func addVideo(_ video: MusicVideo, toPlaylist id: UUID) throws {
        guard let record = try playlistRecord(id: id) else { return }

        // Tránh thêm trùng video.
        if record.items.contains(where: { $0.videoID == video.id }) {
            return
        }

        let item = PlaylistItemRecord(
            videoID: video.id,
            title: video.title,
            channelTitle: video.channelTitle,
            thumbnailURLString: video.thumbnailURL?.absoluteString,
            viewCount: video.viewCount ?? 0
        )
        record.items.append(item)
        try context.save()
    }

    /// Xoá một video khỏi playlist.
    func removeVideo(videoID: String, fromPlaylist id: UUID) throws {
        guard let record = try playlistRecord(id: id) else { return }
        record.items.removeAll { $0.videoID == videoID }
        try context.save()
    }

    /// Sắp xếp lại thứ tự video theo danh sách ID cung cấp.
    func setVideoOrder(_ videoIDs: [String], inPlaylist id: UUID) throws {
        guard let record = try playlistRecord(id: id) else { return }

        // Xây map videoID → record để sắp xếp lại đúng thứ tự mới.
        let itemMap = Dictionary(uniqueKeysWithValues: record.items.map { ($0.videoID, $0) })

        // Giữ các video không nằm trong danh sách (nếu có) ở cuối.
        let ordered = videoIDs.compactMap { itemMap[$0] }
        let rest = record.items.filter { !videoIDs.contains($0.videoID) }

        record.items = ordered + rest
        try context.save()
    }

    // MARK: - Private

    /// Tìm `PlaylistRecord` theo id.
    private func playlistRecord(id: UUID) throws -> PlaylistRecord? {
        let predicate = #Predicate<PlaylistRecord> { $0.id == id }
        var descriptor = FetchDescriptor<PlaylistRecord>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Chuyển `PlaylistRecord` sang `Playlist` domain.
    private static func mapToDomain(_ record: PlaylistRecord) -> Playlist {
        Playlist(
            id: record.id,
            name: record.name,
            createdAt: record.createdAt,
            videos: record.items.map(mapItemToDomain)
        )
    }

    /// Chuyển `PlaylistItemRecord` sang `MusicVideo` domain.
    private static func mapItemToDomain(_ item: PlaylistItemRecord) -> MusicVideo {
        MusicVideo(
            id: item.videoID,
            title: item.title,
            channelID: "",
            channelTitle: item.channelTitle,
            thumbnailURL: item.thumbnailURLString.flatMap(URL.init(string:)),
            viewCount: item.viewCount > 0 ? item.viewCount : nil
        )
    }
}
