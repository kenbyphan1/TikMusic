import Foundation

/// Xây dựng `URLRequest` hoàn chỉnh từ một `APIEndpoint`.
///
/// Tách biệt việc "tạo request" khỏi "gửi request" giúp dễ test và dễ mở rộng.
enum RequestBuilder {

    /// Dựng `URLRequest` từ endpoint.
    ///
    /// - Parameter endpoint: endpoint cần dựng request.
    /// - Returns: `URLRequest` sẵn sàng gửi đi.
    /// - Throws: `APIError.invalidURL` nếu không thể tạo URL hợp lệ.
    static func build(from endpoint: APIEndpoint) throws -> URLRequest {
        // Nối path vào baseURL.
        var url = endpoint.baseURL.appending(path: endpoint.path)

        // Gắn query parameters (URLComponents tự encode phần trăm).
        if !endpoint.queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = endpoint.queryItems
            guard let finalURL = components?.url else {
                throw APIError.invalidURL
            }
            url = finalURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.timeoutInterval = endpoint.timeoutInterval

        // Gắn headers mặc định + headers của endpoint.
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
