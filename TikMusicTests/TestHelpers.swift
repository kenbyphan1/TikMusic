import Foundation
@testable import TikMusic

/// Mock `NetworkSession` cho phép trả về dữ liệu/response theo kịch bản test.
final class MockNetworkSession: NetworkSession, @unchecked Sendable {

    /// Closure xử lý mỗi request — trả về (data, response).
    var handler: (URLRequest) async throws -> (Data, URLResponse)

    /// Số request đã gửi (dùng để kiểm tra retry).
    private(set) var requestCount = 0

    private let lock = NSLock()

    init(handler: @escaping (URLRequest) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.lock()
        requestCount += 1
        lock.unlock()
        return try await handler(request)
    }
}

/// Factory tạo HTTPURLResponse cho test.
enum HTTPTestResponse {
    static func make(statusCode: Int, url: URL = URL(string: "https://test.example/api")!) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

/// Endpoint mẫu dùng trong test.
struct TestEndpoint: APIEndpoint {
    var baseURL: URL { URL(string: "https://test.example")! }
    var path: String { "/api/v1/test" }
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "q", value: "phonk music"), URLQueryItem(name: "max", value: "10")]
    }
}

/// Đếm số request với một handler chia sẻ (dùng cho retry test).
final class SharedHandler {
    var handler: (URLRequest) async throws -> (Data, URLResponse)
    init(handler: @escaping (URLRequest) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }
}
