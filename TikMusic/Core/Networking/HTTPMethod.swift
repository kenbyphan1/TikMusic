import Foundation

/// HTTP method dùng trong request.
///
/// Được chuẩn hoá theo chuẩn RFC 7231, đủ cho mọi endpoint mà ứng dụng cần.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
