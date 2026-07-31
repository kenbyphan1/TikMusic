import Foundation

/// Logger cho tầng networking.
///
/// Chỉ ghi log trong chế độ DEBUG để tránh lộ thông tin nhạy cảm
/// và giảm overhead ở chế độ Release.
enum NetworkLogger {

    /// Ghi log một request (method, URL, headers, body).
    static func logRequest(_ request: URLRequest) {
        var output = "\n========== REQUEST ==========\n"
        output += "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "nil")\n"
        output += "Headers: \(request.allHTTPHeaderFields ?? [:])\n"
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            output += "Body: \(bodyString)\n"
        }
        AppLogger.network.log("\(output, privacy: .public)")
    }

    /// Ghi log một response (status, URL, dung lượng dữ liệu).
    static func logResponse(_ response: URLResponse, data: Data) {
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        var output = "\n========== RESPONSE ==========\n"
        output += "Status: \(status) | \(response.url?.absoluteString ?? "nil")\n"
        output += "Data: \(data.count) bytes\n"
        AppLogger.network.log("\(output, privacy: .public)")
    }

    /// Ghi log một lỗi kèm số lần thử.
    static func logError(_ error: Error, attempt: Int) {
        AppLogger.network.log("Attempt \(attempt + 1) failed: \(error.localizedDescription, privacy: .public)")
    }
}
