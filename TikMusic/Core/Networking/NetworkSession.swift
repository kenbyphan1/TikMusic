import Foundation

/// Abstraction cho URLSession để có thể mock trong unit test.
///
/// APIClient chỉ phụ thuộc vào giao thức này thay vì URLSession cụ thể,
/// giúp kiểm thử các kịch bản mạng (lỗi, retry, timeout...) dễ dàng.
protocol NetworkSession {
    /// Lấy dữ liệu cho một request (tương đương `URLSession.data(for:)`).
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}
