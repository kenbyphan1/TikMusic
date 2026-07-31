import Foundation

/// Client gửi request và decode response cho toàn bộ ứng dụng.
///
/// Đảm nhận các nhiệm vụ xuyên suốt:
/// - Build request từ endpoint (thông qua `RequestBuilder`).
/// - Gửi request qua `NetworkSession` (mặc định là `URLSession`).
/// - Kiểm tra HTTP status, decode lỗi server, decode kiểu mong đợi.
/// - Tự động retry với backoff cho các lỗi mạng tạm thời và lỗi 5xx/429.
/// - Log request/response qua `NetworkLogger` ở chế độ DEBUG.
struct APIClient {
    /// Session thực hiện network call (có thể thay bằng mock trong test).
    let session: NetworkSession

    /// Số lần retry tối đa (mặc định 2).
    let maxRetries: Int

    /// Thời gian chờ cơ bản trước mỗi lần retry (giây).
    let retryBaseDelay: TimeInterval

    /// Có bật log hay không (mặc định theo DEBUG).
    let isLoggingEnabled: Bool

    /// Khởi tạo client.
    init(
        session: NetworkSession,
        maxRetries: Int = 2,
        retryBaseDelay: TimeInterval = 0.5,
        isLoggingEnabled: Bool = AppLogger.isDebug
    ) {
        self.session = session
        self.maxRetries = maxRetries
        self.retryBaseDelay = retryBaseDelay
        self.isLoggingEnabled = isLoggingEnabled
    }

    /// Gửi request và decode response sang kiểu `T`.
    ///
    /// - Parameters:
    ///   - endpoint: endpoint cần gọi.
    ///   - type: kiểu dữ liệu decode.
    /// - Returns: đối tượng đã decode.
    /// - Throws: `APIError` nếu có lỗi xảy ra.
    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        let request = try RequestBuilder.build(from: endpoint)

        if isLoggingEnabled {
            NetworkLogger.logRequest(request)
        }

        var lastError: Error = APIError.unknown

        // Vòng lặp thực hiện request + retry theo chính sách backoff.
        for attempt in 0...maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                let decoded: T = try Self.handleResponse(data: data, response: response, as: type)

                if isLoggingEnabled {
                    NetworkLogger.logResponse(response, data: data)
                }
                return decoded
            } catch {
                lastError = error
                if isLoggingEnabled {
                    NetworkLogger.logError(error, attempt: attempt)
                }

                // Chỉ retry khi lỗi có thể phục hồi được.
                guard Self.isRetryable(error), attempt < maxRetries else {
                    break
                }

                // Backoff: tăng dần thời gian chờ theo số lần retry.
                let delay = retryBaseDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError
    }

    /// Xử lý response: kiểm tra status code, decode lỗi hoặc decode dữ liệu.
    private static func handleResponse<T: Decodable>(
        data: Data,
        response: URLResponse,
        as type: T.Type
    ) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let statusCode = httpResponse.statusCode
        let okRange = 200...299

        if !okRange.contains(statusCode) {
            throw Self.error(from: data, statusCode: statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// Dựng `APIError` từ dữ liệu lỗi trả về bởi server (nếu có cấu trúc JSON).
    private static func error(from data: Data, statusCode: Int) -> APIError {
        // Trường hợp đặc biệt: vượt quá quota.
        if statusCode == 403, let text = String(data: data, encoding: .utf8),
           text.contains("quotaExceeded") {
            return .quotaExceeded
        }

        // Thử decode body lỗi chuẩn của Google API.
        let decoder = JSONDecoder()
        if let errorDTO = try? decoder.decode(YouTubeErrorResponseDTO.self, from: data),
           let message = errorDTO.error?.message {
            return .httpStatus(statusCode, message: message)
        }

        // Trả về thông điệp thô nếu có thể đọc được.
        let fallbackMessage = String(data: data, encoding: .utf8)
        return .httpStatus(statusCode, message: fallbackMessage)
    }

    /// Xác định lỗi nào nên retry.
    ///
    /// Retry khi:
    /// - Lỗi mạng tạm thời (timeout, mất kết nối, ...).
    /// - Server lỗi 5xx (500, 502, 503, 504).
    /// - Quá tải 429.
    private static func isRetryable(_ error: Error) -> Bool {
        switch error {
        case APIError.network:
            return true
        case APIError.httpStatus(let code, _):
            return code == 429 || (500...599).contains(code)
        case APIError.quotaExceeded:
            return false
        case APIError.invalidResponse:
            return true
        default:
            return false
        }
    }
}
