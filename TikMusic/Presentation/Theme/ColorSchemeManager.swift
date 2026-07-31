import Foundation
import Observation
import SwiftUI

/// Quản lý chủ đề giao diện của ứng dụng.
///
/// Cho phép người dùng chọn: Theo hệ thống / Sáng / Tối.
/// Lựa chọn được lưu trong `UserDefaults`.
///
/// Lưu ý: dùng computed property + backing stored để tránh `didSet`
/// (an toàn hơn với macro `@Observable`).
@Observable
final class ColorSchemeManager {

    /// Lựa chọn chủ đề của người dùng.
    enum ThemePreference: String, CaseIterable, Identifiable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        /// Tên hiển thị.
        var title: String {
            switch self {
            case .system: return "Theo hệ thống"
            case .light: return "Sáng"
            case .dark: return "Tối"
            }
        }

        /// Biểu tượng SF Symbol.
        var symbolName: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }

    /// Key lưu trong UserDefaults.
    private static let storageKey = "appearance_preference_v1"

    /// UserDefaults dùng để đọc/ghi.
    private let defaults: UserDefaults

    /// Giá trị lưu trữ nội bộ (được @Observable theo dõi).
    private var storedPreference: ThemePreference

    /// Lựa chọn hiện tại; tự lưu vào UserDefaults khi thay đổi.
    var preference: ThemePreference {
        get { storedPreference }
        set {
            storedPreference = newValue
            defaults.set(newValue.rawValue, forKey: Self.storageKey)
        }
    }

    /// Khởi tạo manager.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let rawValue = defaults.string(forKey: Self.storageKey)
            ?? ThemePreference.system.rawValue
        self.storedPreference = ThemePreference(rawValue: rawValue) ?? .system
    }

    /// `ColorScheme` đã chọn (nil = theo hệ thống).
    var resolvedScheme: ColorScheme? {
        switch preference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
