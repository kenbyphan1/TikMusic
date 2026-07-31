import SwiftUI

/// Bộ định nghĩa chung cho giao diện: màu sắc, gradient, kích thước.
///
/// Tập trung các hằng số thiết kế tại một nơi để giao diện nhất quán
/// và dễ dàng thay đổi chủ đề.
enum AppTheme {

    /// Bo góc mặc định cho thẻ.
    static let cardCornerRadius: CGFloat = 18

    /// Bo góc mặc định cho nút / chip.
    static let chipCornerRadius: CGFloat = 14

    /// Màu nhấn (accent) — hồng TikTok.
    static let accent = Color(red: 0.98, green: 0.20, blue: 0.78)

    /// Gradient nhấn: hồng → tím → xanh (phong cách TikTok).
    static let accentGradient = LinearGradient(
        colors: [.pink, .purple, .blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradient nền mờ cho header.
    static let headerGradient = LinearGradient(
        colors: [Color.pink.opacity(0.18), Color.purple.opacity(0.10), Color.blue.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Màu nền skeleton.
    static let skeletonBase = Color(.systemGray5)

    /// Khoảng cách padding chuẩn.
    static let padding: CGFloat = 16

    /// Font tiêu đề lớn.
    static let largeTitleFont = Font.system(size: 34, weight: .heavy, design: .rounded)

    /// Font tiêu đề chính.
    static let titleFont = Font.system(size: 22, weight: .bold, design: .rounded)

    /// Font tiêu đề phụ.
    static let headlineFont = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Font nội dung.
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)

    /// Font phụ.
    static let captionFont = Font.system(size: 13, weight: .regular, design: .rounded)
}

// MARK: - Hỗ trợ format số

/// Định dạng số gọn gàng: 1.2K, 3.4M...
enum CompactNumberFormatter {
    /// Định dạng số lượng (lượt xem) thành chuỗi rút gọn.
    static func compact(_ value: Int) -> String {
        let absValue = abs(Double(value))
        let formatter = "%.1f"
        switch absValue {
        case 1_000_000_000...:
            return String(format: formatter, absValue / 1_000_000_000) + "B"
        case 1_000_000...:
            return String(format: formatter, absValue / 1_000_000) + "M"
        case 1_000...:
            return String(format: formatter, absValue / 1_000) + "K"
        default:
            return "\(value)"
        }
    }
}
