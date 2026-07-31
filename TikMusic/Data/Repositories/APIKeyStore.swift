import Foundation
import Security

/// Lỗi phát sinh khi thao tác với Keychain.
enum KeychainError: LocalizedError {
    /// Trạng thái không mong đợi từ Security framework.
    case unexpectedStatus(OSStatus)
    /// Dữ liệu lưu trong Keychain không hợp lệ.
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            return "Lỗi Keychain (mã \(status))."
        case .invalidData:
            return "Dữ liệu trong Keychain không hợp lệ."
        }
    }
}

/// Lưu trữ an toàn API Key trong Keychain của iOS.
///
/// Keychain là nơi mã hoá do hệ điều hành quản lý — an toàn hơn
/// rất nhiều so với UserDefaults. API Key người dùng nhập trong
/// Cài đặt sẽ được lưu tại đây.
struct APIKeyStore {

    /// Service identifier của generic password.
    private let service = "com.tikmusic.app.apikey"
    /// Account identifier của generic password.
    private let account = "youtube-data-api-key"

    /// Lưu (hoặc cập nhật) một API Key.
    func save(_ key: String) throws {
        let data = Data(key.utf8)

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        // Xoá bản cũ trước (nếu có) để tránh trùng lặp.
        SecItemDelete(baseQuery as CFDictionary)

        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Đọc API Key đã lưu, `nil` nếu chưa có.
    func load() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // Chưa có mục nào → không phải lỗi.
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return key
    }

    /// Xoá API Key đã lưu.
    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
