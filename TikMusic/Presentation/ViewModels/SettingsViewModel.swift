import Foundation
import Observation

/// ViewModel cho màn hình Cài đặt.
///
/// Chịu trách nhiệm: chủ đề giao diện, xoá cache, quản lý API Key,
/// thông tin phiên bản ứng dụng.
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Dependencies

    private let colorSchemeManager: ColorSchemeManager
    private let apiKeyProvider: APIKeyProvider
    private let imageCache = ImageCache.shared

    /// Khởi tạo ViewModel.
    init(colorSchemeManager: ColorSchemeManager, apiKeyProvider: APIKeyProvider) {
        self.colorSchemeManager = colorSchemeManager
        self.apiKeyProvider = apiKeyProvider
    }

    // MARK: - Giao diện

    /// Lựa chọn chủ đề hiện tại.
    var themePreference: ColorSchemeManager.ThemePreference {
        get { colorSchemeManager.preference }
        set { colorSchemeManager.preference = newValue }
    }

    // MARK: - Cache

    /// Dung lượng cache ảnh hiện tại (chuỗi đã định dạng).
    var cacheSizeText: String {
        let bytes = imageCache.diskSizeBytes
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    /// Xoá toàn bộ cache (RAM + đĩa).
    func clearCache() {
        imageCache.clearAll()
    }

    // MARK: - API Key

    /// API Key đã được cấu hình (build hoặc runtime).
    var isAPIKeyConfigured: Bool { apiKeyProvider.isConfigured }

    /// Có key runtime do người dùng nhập không.
    var hasRuntimeKey: Bool { apiKeyProvider.runtimeKey != nil }

    /// Lưu key do người dùng nhập (lưu vào Keychain).
    func saveRuntimeKey(_ key: String) {
        apiKeyProvider.runtimeKey = key
    }

    /// Xoá key runtime, quay về dùng build-time key.
    func resetRuntimeKey() {
        apiKeyProvider.resetRuntimeKey()
    }

    // MARK: - Thông tin app

    /// Chuỗi phiên bản app (version + build).
    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
