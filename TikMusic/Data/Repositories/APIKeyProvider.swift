import Foundation
import Observation

/// Quản lý API Key của YouTube với hai nguồn:
///
/// 1. **Build-time key**: đọc từ `Info.plist` (giá trị từ `Config.xcconfig`).
///    Không hardcode trong mã nguồn, không commit lên git.
/// 2. **Runtime key**: người dùng nhập trong Cài đặt, lưu trong Keychain.
///    Được ưu tiên hơn key build-time.
///
/// Sử dụng `@Observable` để UI phản ứng ngay khi key thay đổi.
/// (Computed property + backing stored để an toàn với macro.)
@Observable
final class APIKeyProvider {

    /// Giá trị placeholder trong Config.xcconfig (chưa được cấu hình).
    static let placeholder = "YOUR_YOUTUBE_API_KEY"

    /// Lưu trữ keychain.
    private let keychain = APIKeyStore()

    /// Key từ Config.xcconfig (build-time).
    private let buildKey: String?

    /// Key runtime lưu nội bộ (được @Observable theo dõi).
    private var storedRuntimeKey: String?

    /// Key người dùng nhập (runtime), lưu trong Keychain.
    var runtimeKey: String? {
        get { storedRuntimeKey }
        set {
            storedRuntimeKey = newValue
            persistIfNeeded()
        }
    }

    /// Khởi tạo provider và đọc trạng thái hiện tại.
    init(bundle: Bundle = .main) {
        buildKey = bundle.object(forInfoDictionaryKey: "YOUTUBE_API_KEY") as? String
        storedRuntimeKey = try? keychain.load()
    }

    /// Key hiệu dụng: runtime (nếu có) → build (nếu có) → nil.
    var effectiveKey: String? {
        if let runtimeKey, isReal(runtimeKey) {
            return runtimeKey
        }
        if let buildKey, isReal(buildKey) {
            return buildKey
        }
        return nil
    }

    /// Đã cấu hình API Key hợp lệ chưa.
    var isConfigured: Bool {
        effectiveKey != nil
    }

    /// Xoá key runtime, quay về dùng build-time key.
    func resetRuntimeKey() {
        storedRuntimeKey = nil
        try? keychain.delete()
    }

    // MARK: - Private

    /// Lưu key xuống Keychain khi thay đổi (hoặc xoá nếu rỗng).
    private func persistIfNeeded() {
        guard let storedRuntimeKey else { return }
        if isReal(storedRuntimeKey) {
            try? keychain.save(storedRuntimeKey)
        } else {
            try? keychain.delete()
        }
    }

    /// Kiểm tra chuỗi có phải key thật (khác rỗng, khác placeholder).
    private func isReal(_ key: String) -> Bool {
        !key.isEmpty && key != Self.placeholder
    }
}
