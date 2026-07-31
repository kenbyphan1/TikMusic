import Foundation

/// Tập hợp mọi lỗi có thể xảy ra trong tầng networking.
///
/// Tuân thủ `LocalizedError` để hiển thị thông báo thân thiện cho người dùng.
enum APIError: LocalizedError {
    /// Không tìm thấy API Key (chưa cấu hình).
    case missingAPIKey

    /// URL không hợp lệ.
    case invalidURL

    /// Response không phải HTTP hoặc không mong đợi.
    case invalidResponse

    /// Server trả về HTTP status code ngoài dải 200...299.
    case httpStatus(Int, message: String?)

    /// Lỗi mạng (mất kết nối, timeout, ...).
    case network(URLError)

    /// Không thể decode dữ liệu về kiểu mong đợi.
    case decoding(Error)

    /// Giới hạn quota của YouTube API bị vượt quá.
    case quotaExceeded

    /// Server trả về thông điệp lỗi có cấu trúc từ API.
    case serverMessage(String)

    /// Lỗi không xác định.
    case unknown

    /// Thông điệp hiển thị cho người dùng.
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Chưa cấu hình API Key. Vui lòng thêm YouTube Data API Key trong Cài đặt."
        case .invalidURL:
            return "URL không hợp lệ."
        case .invalidResponse:
            return "Phản hồi từ server không hợp lệ."
        case .httpStatus(let code, let message):
            if code == 403 {
                return "Không được phép truy cập (403). Vui lòng kiểm tra API Key."
            }
            if let message {
                return "Lỗi HTTP \(code): \(message)"
            }
            return "Lỗi HTTP \(code)."
        case .network(let error):
            return "Lỗi mạng: \(error.localizedDescription)"
        case .decoding:
            return "Không thể đọc dữ liệu từ server."
        case .quotaExceeded:
            return "Đã vượt quá giới hạn quota của YouTube API. Vui lòng thử lại sau."
        case .serverMessage(let message):
            return message
        case .unknown:
            return "Đã xảy ra lỗi không xác định."
        }
    }
}
