import Foundation

/// Lưu trữ lịch sử xem Short: "gần đây" và "tiếp tục xem".
///
/// - **Recently watched**: danh sách Short đã mở gần đây (mới nhất trước).
/// - **Continue watching**: vị trí phát cuối cùng của từng Short để quay lại
///   tiếp tục xem đúng đoạn đã dừng.
///
/// Dữ liệu lưu dạng JSON trong Application Support.
final class ShortHistoryStore {

    /// Số mục tối đa được giữ lại.
    static let maxItems = 30

    private let store: JSONFileStore

    /// Khởi tạo với store ghi lên đĩa.
    init(store: JSONFileStore) {
        self.store = store
    }

    /// Bản ghi đã xem.
    struct Entry: Codable, Identifiable, Sendable, Equatable {
        let id: String
        let short: ShortVideo
        let playedAt: Date
        let lastPlayedSeconds: Double
    }

    /// Container lưu trong file (để mở rộng trong tương lai).
    private struct Container: Codable {
        var entries: [Entry] = []
    }

    /// Danh sách Short xem gần đây (mới nhất trước).
    var recentEntries: [Entry] {
        let entries = (try? store.load(Container.self))?.entries ?? []
        return entries.sorted { $0.playedAt > $1.playedAt }
    }

    /// Danh sách Short "tiếp tục xem" (chưa xem hết, mới nhất trước).
    var continueWatchingEntries: [Entry] {
        recentEntries.filter { $0.lastPlayedSeconds > 1 }
    }

    /// Ghi nhận một lần xem Short.
    ///
    /// - Parameters:
    ///   - short: Short đang xem.
    ///   - seconds: vị trí phát hiện tại (giây).
    func record(short: ShortVideo, seconds: Double) {
        var container = (try? store.load(Container.self)) ?? Container()

        // Xoá bản ghi trùng rồi chèn lên đầu.
        container.entries.removeAll { $0.id == short.id }
        container.entries.insert(
            Entry(
                id: short.id,
                short: short,
                playedAt: Date(),
                lastPlayedSeconds: seconds
            ),
            at: 0
        )

        if container.entries.count > Self.maxItems {
            container.entries = Array(container.entries.prefix(Self.maxItems))
        }

        try? store.save(container)
    }

    /// Cập nhật vị trí phát (gọi định kỳ trong lúc xem) mà không thay đổi
    /// thứ tự thời gian xem.
    func updateProgress(id: String, seconds: Double) {
        var container = (try? store.load(Container.self)) ?? Container()
        guard let index = container.entries.firstIndex(where: { $0.id == id }) else { return }
        container.entries[index].lastPlayedSeconds = seconds
        try? store.save(container)
    }

    /// Vị trí phát cuối cùng của một Short (mặc định 0).
    func lastPlayedSeconds(id: String) -> Double {
        let container = (try? store.load(Container.self)) ?? Container()
        return container.entries.first(where: { $0.id == id })?.lastPlayedSeconds ?? 0
    }

    /// Xoá toàn bộ lịch sử.
    func clear() {
        try? store.clear()
    }
}
