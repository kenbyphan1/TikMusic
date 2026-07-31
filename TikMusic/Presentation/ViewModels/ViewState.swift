import Foundation

/// Trạng thái chung của một màn hình tải dữ liệu.
///
/// Dùng chung cho các ViewModel để UI render đúng view tương ứng
/// (loading / loaded / empty / error).
enum ViewState: Equatable {
    /// Chưa tải gì.
    case idle

    /// Đang tải dữ liệu.
    case loading

    /// Tải thành công.
    case loaded

    /// Tải thành công nhưng không có dữ liệu.
    case empty

    /// Tải thất bại kèm thông điệp lỗi.
    case error(String)

    /// Bằng nhau (so sánh cho trường hợp thông điệp lỗi).
    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded), (.empty, .empty):
            return true
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }
}
