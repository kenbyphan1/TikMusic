import Foundation

/// Cache ghi nhớ video thay thế đã phát được.
///
/// Ánh xạ `videoID gốc (không phát được) → MusicVideo thay thế (đã xác minh
/// phát được)`. Khi mở lại một video bị chặn nhúng, dùng ngay video thay thế
/// trong cache thay vì phải tìm lại — mở nhanh hơn và không tốn quota API.
///
/// Dữ liệu lưu dạng JSON (`[String: MusicVideo]`) trong Application Support.
final class PlaybackCacheStore {

    private let store: JSONFileStore

    /// Khởi tạo với store ghi lên đĩa.
    init(store: JSONFileStore) {
        self.store = store
    }

    /// Lấy video thay thế đã biết cho một video gốc (nil nếu chưa có).
    func alternative(for videoID: String) -> MusicVideo? {
        guard let cache: [String: MusicVideo] = try? store.load([String: MusicVideo].self) else {
            return nil
        }
        return cache[videoID]
    }

    /// Ghi nhớ video thay thế cho một video gốc.
    func save(alternative: MusicVideo, for videoID: String) {
        var cache: [String: MusicVideo] = (try? store.load([String: MusicVideo].self)) ?? [:]
        cache[videoID] = alternative
        try? store.save(cache)
    }
}
