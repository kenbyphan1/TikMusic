import Foundation
import os

/// Logger tập trung của ứng dụng.
///
/// Sử dụng `OSLog` để tích hợp với Console.app và Instruments.
/// Ở chế độ Release, mọi log ở mức debug/network đều bị vô hiệu hoá.
enum AppLogger {
    /// `true` khi đang build ở chế độ DEBUG.
    static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.tikmusic.app"

    /// Logger cho tầng mạng.
    static let network = Logger(subsystem: subsystem, category: "Network")

    /// Logger cho tầng dữ liệu / local storage.
    static let storage = Logger(subsystem: subsystem, category: "Storage")

    /// Logger cho tầng UI / ViewModel.
    static let ui = Logger(subsystem: subsystem, category: "UI")

    /// Logger cho luồng điều khiển chung.
    static let general = Logger(subsystem: subsystem, category: "General")

    /// Ghi log lỗi (luôn ghi ở cả hai chế độ).
    static func error(_ message: String, category: Logger = general) {
        category.error("\(message, privacy: .public)")
    }

    /// Ghi log thông tin (chỉ ở chế độ DEBUG).
    static func info(_ message: String, category: Logger = general) {
        guard isDebug else { return }
        category.info("\(message, privacy: .public)")
    }
}
