import SwiftUI

/// Danh sách các chủ đề nhạc phổ biến trên TikTok.
///
/// Mỗi chủ đề ánh xạ tới một chuỗi tìm kiếm trên YouTube Data API
/// và có màu gradient riêng phục vụ giao diện.
enum MusicCategory: String, CaseIterable, Identifiable, Codable, Sendable {

    case tiktokViral = "TikTok Viral"
    case trending = "Trending"
    case remix = "Remix"
    case mashup = "Mashup"
    case phonk = "Phonk"
    case chill = "Chill"
    case sad = "Sad"
    case edm = "EDM"
    case nightcore = "Nightcore"
    case kpop = "KPOP"
    case usuk = "USUK"
    case anime = "Anime"
    case lofi = "Lofi"

    /// Định danh dùng trong SwiftUI.
    var id: String { rawValue }

    /// Tên hiển thị.
    var title: String { rawValue }

    /// Chuỗi truy vấn gửi lên YouTube. Một số chủ đề thêm từ khoá
    /// "music" để tăng độ chính xác của kết quả.
    var searchQuery: String {
        switch self {
        case .tiktokViral: return "tiktok viral songs"
        case .trending: return "trending music"
        case .remix: return "remix music"
        case .mashup: return "mashup music"
        case .phonk: return "phonk music"
        case .chill: return "chill music"
        case .sad: return "sad songs"
        case .edm: return "edm music"
        case .nightcore: return "nightcore"
        case .kpop: return "kpop music"
        case .usuk: return "us uk music"
        case .anime: return "anime music"
        case .lofi: return "lofi music"
        }
    }

    /// Biểu tượng SF Symbol cho từng chủ đề.
    var symbolName: String {
        switch self {
        case .tiktokViral: return "flame.fill"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .remix: return "arrow.triangle.2.circlepath"
        case .mashup: return "square.stack.3d.up.fill"
        case .phonk: return "speaker.wave.3.fill"
        case .chill: return "wind"
        case .sad: return "cloud.rain.fill"
        case .edm: return "bolt.fill"
        case .nightcore: return "moon.stars.fill"
        case .kpop: return "music.mic"
        case .usuk: return "globe.americas.fill"
        case .anime: return "sparkles"
        case .lofi: return "headphones"
        }
    }

    /// Màu gradient đặc trưng của chủ đề.
    var gradientColors: [Color] {
        switch self {
        case .tiktokViral: return [Color.pink, Color.purple]
        case .trending: return [Color.orange, Color.pink]
        case .remix: return [Color.purple, Color.blue]
        case .mashup: return [Color.teal, Color.cyan]
        case .phonk: return [Color.indigo, Color.purple]
        case .chill: return [Color.mint, Color.teal]
        case .sad: return [Color.blue, Color.indigo]
        case .edm: return [Color.yellow, Color.orange]
        case .nightcore: return [Color.indigo, Color.black]
        case .kpop: return [Color.pink, Color.orange]
        case .usuk: return [Color.blue, Color.cyan]
        case .anime: return [Color.purple, Color.pink]
        case .lofi: return [Color.brown, Color.orange]
        }
    }
}
