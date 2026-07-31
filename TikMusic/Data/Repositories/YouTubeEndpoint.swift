import Foundation

/// Định nghĩa các endpoint của YouTube Data API v3.
enum YouTubeEndpoint {
    /// Tìm kiếm video (dùng cho trang chủ theo chủ đề và tìm kiếm tự do).
    case search(apiKey: String, query: String, pageToken: String?, maxResults: Int, regionCode: String)

    /// Lấy chi tiết video theo danh sách ID (bao gồm thống kê, thời lượng).
    case videos(apiKey: String, ids: [String])
}

// MARK: - APIEndpoint

extension YouTubeEndpoint: APIEndpoint {
    /// URL gốc của Google API.
    var baseURL: URL {
        URL(string: "https://www.googleapis.com")!
    }

    /// Đường dẫn tương ứng với từng endpoint.
    var path: String {
        switch self {
        case .search:
            return "/youtube/v3/search"
        case .videos:
            return "/youtube/v3/videos"
        }
    }

    /// Cả hai endpoint đều dùng GET.
    var method: HTTPMethod {
        .get
    }

    /// Query parameters theo từng endpoint.
    var queryItems: [URLQueryItem] {
        switch self {
        case .search(let apiKey, let query, let pageToken, let maxResults, let regionCode):
            var items = [
                URLQueryItem(name: "key", value: apiKey),
                URLQueryItem(name: "part", value: "snippet"),
                URLQueryItem(name: "type", value: "video"),
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "maxResults", value: "\(maxResults)"),
                URLQueryItem(name: "safeSearch", value: "strict"),
            ]
            if let pageToken {
                items.append(URLQueryItem(name: "pageToken", value: pageToken))
            }
            if !regionCode.isEmpty {
                items.append(URLQueryItem(name: "regionCode", value: regionCode))
            }
            return items

        case .videos(let apiKey, let ids):
            return [
                URLQueryItem(name: "key", value: apiKey),
                URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
                URLQueryItem(name: "id", value: ids.joined(separator: ",")),
            ]
        }
    }
}
