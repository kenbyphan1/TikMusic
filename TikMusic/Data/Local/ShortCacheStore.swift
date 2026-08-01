import Foundation

/// Cache metadata + thumbnail của Short xuống đĩa (JSON) để xem offline.
///
/// Chỉ lưu metadata + URL thumbnail (không lưu video) — tiết kiệm dung lượng
/// và tuân theo yêu cầu "offline cache: thumbnail + metadata only".
final class ShortCacheStore {

    /// Số Short tối đa được giữ trong cache.
    static let maxItems = 50

    private let store: JSONFileStore

    /// Khởi tạo với store ghi lên đĩa.
    init(store: JSONFileStore) {
        self.store = store
    }

    /// Ghi danh sách Short xuống cache (giữ tối đa `maxItems`).
    func save(_ videos: [ShortVideo]) {
        guard !videos.isEmpty else { return }
        var merged = load()
        let knownIDs = Set(merged.map(\.id))
        merged.append(contentsOf: videos.filter { !knownIDs.contains($0.id) })

        if merged.count > Self.maxItems {
            merged = Array(merged.suffix(Self.maxItems))
        }

        try? store.save(merged)
    }

    /// Đọc danh sách Short đã cache.
    func load() -> [ShortVideo] {
        (try? store.load([ShortVideo].self)) ?? []
    }

    /// Xoá toàn bộ cache.
    func clear() {
        try? store.clear()
    }
}
