import Foundation

/// Bộ nhớ đệm nhanh trong RAM, an toàn với luồng (thread-safe).
///
/// Dựa trên `NSCache` — tự động giải phóng khi thiếu bộ nhớ,
/// hỗ trợ giới hạn số lượng phần tử và tổng chi phí.
final class MemoryCache<Key: AnyObject, Value: AnyObject> {

    /// Cache lưu trữ bên trong.
    private let cache = NSCache<Key, Value>()

    /// Khởi tạo cache với giới hạn tuỳ chọn.
    ///
    /// - Parameters:
    ///   - countLimit: số lượng phần tử tối đa.
    ///   - totalCostLimit: tổng chi phí (bytes) tối đa.
    init(countLimit: Int = 0, totalCostLimit: Int = 0) {
        if countLimit > 0 {
            cache.countLimit = countLimit
        }
        if totalCostLimit > 0 {
            cache.totalCostLimit = totalCostLimit
        }
    }

    /// Lưu một giá trị vào cache.
    func set(_ value: Value, forKey key: Key, cost: Int = 0) {
        if cost > 0 {
            cache.setObject(value, forKey: key, cost: cost)
        } else {
            cache.setObject(value, forKey: key)
        }
    }

    /// Lấy giá trị từ cache, `nil` nếu không có.
    func value(forKey key: Key) -> Value? {
        cache.object(forKey: key)
    }

    /// Xoá toàn bộ cache.
    func removeAll() {
        cache.removeAllObjects()
    }
}
