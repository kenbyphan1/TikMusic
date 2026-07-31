import Foundation

/// Giao thức mô tả một endpoint API.
///
/// Mỗi endpoint định nghĩa cách xây dựng request tương ứng:
/// URL gốc, path, method, query parameters, headers, body và timeout.
protocol APIEndpoint {
    /// URL gốc của dịch vụ (ví dụ `https://www.googleapis.com`).
    var baseURL: URL { get }

    /// Đường dẫn tương đối, ví dụ `/youtube/v3/search`.
    var path: String { get }

    /// HTTP method.
    var method: HTTPMethod { get }

    /// Query parameters (được đánh dấu phần trăm encode tự động).
    var queryItems: [URLQueryItem] { get }

    /// HTTP headers bổ sung.
    var headers: [String: String] { get }

    /// Body dạng JSON (nil nếu không có body).
    var body: Data? { get }

    /// Thời gian chờ tối đa cho request.
    var timeoutInterval: TimeInterval { get }
}

extension APIEndpoint {
    /// Mặc định không có headers bổ sung.
    var headers: [String: String] { [:] }

    /// Mặc định không có body.
    var body: Data? { nil }

    /// Mặc định timeout 30 giây.
    var timeoutInterval: TimeInterval { 30 }

    /// Mặc định không có query parameters.
    var queryItems: [URLQueryItem] { [] }
}
