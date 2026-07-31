import Foundation

/// Lưu trữ lịch sử tìm kiếm trong `UserDefaults`.
///
/// Giữ tối đa một số lượng mục nhất định, không trùng lặp,
/// mục mới nhất nằm ở đầu danh sách.
final class SearchHistoryStore {

    /// Số mục tối đa được giữ lại.
    static let maxItems = 10

    /// Key lưu trong UserDefaults.
    private static let storageKey = "search_history_v1"

    /// UserDefaults dùng để đọc/ghi (có thể thay bằng suite trong test).
    private let defaults: UserDefaults

    /// Khởi tạo store.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Danh sách tìm kiếm gần đây (mới nhất trước).
    var recentSearches: [String] {
        defaults.stringArray(forKey: Self.storageKey) ?? []
    }

    /// Thêm một từ khoá vào lịch sử.
    ///
    /// - Xoá bản trùng nếu có rồi chèn lên đầu.
    /// - Cắt bớt nếu vượt quá giới hạn.
    func add(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var history = recentSearches
        history.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        history.insert(trimmed, at: 0)

        if history.count > Self.maxItems {
            history = Array(history.prefix(Self.maxItems))
        }

        defaults.set(history, forKey: Self.storageKey)
    }

    /// Xoá một từ khoá khỏi lịch sử.
    func remove(_ query: String) {
        var history = recentSearches
        history.removeAll { $0 == query }
        defaults.set(history, forKey: Self.storageKey)
    }

    /// Xoá toàn bộ lịch sử.
    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
