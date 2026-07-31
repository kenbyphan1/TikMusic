import SwiftUI
import WebKit

/// Trình phát YouTube nhúng (embed) dựa trên WKWebView.
///
/// Không cần SDK của YouTube. Load trực tiếp URL `/embed/<id>` kèm
/// HTTP header `Referer: https://www.youtube.com` — WKWebView không
/// tự gửi Referer hợp lệ (origin của app không phải HTTPS), nên phải
/// gán thủ công để YouTube chấp nhận cấu hình player. Tránh lỗi
/// 153 "Video player configuration error" và 152-4 "This video is
/// not available" trên iOS.
struct YouTubePlayerView: UIViewRepresentable {

    /// ID video trên YouTube.
    let videoID: String

    /// Tự động phát khi hiển thị.
    var autoPlay: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator

        // Chỉ (re)load khi video hoặc trạng thái autoplay thay đổi.
        guard coordinator.loadedVideoID != videoID || coordinator.loadedAutoPlay != autoPlay else {
            return
        }

        guard let url = Self.embedURL(videoID: videoID, autoPlay: autoPlay) else {
            coordinator.loadedVideoID = videoID
            coordinator.loadedAutoPlay = autoPlay
            return
        }

        var request = URLRequest(url: url)
        // Referer hợp lệ giúp YouTube xác minh embedder → hết lỗi 153/152-4.
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Referer")
        webView.load(request)

        coordinator.loadedVideoID = videoID
        coordinator.loadedAutoPlay = autoPlay
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Coordinator theo dõi trạng thái điều hướng của web view.
    final class Coordinator: NSObject, WKNavigationDelegate {
        /// Video đã load gần nhất (tránh reload lại liên tục).
        var loadedVideoID: String?
        var loadedAutoPlay = false

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            AppLogger.error("YouTubePlayer load lỗi: \(error.localizedDescription)")
        }
    }

    /// URL embed video YouTube, kèm các tham số trình phát cơ bản.
    private static func embedURL(videoID: String, autoPlay: Bool) -> URL? {
        let autoplay = autoPlay ? "1" : "0"
        let query = "autoplay=\(autoplay)&playsinline=1&rel=0&modestbranding=1&controls=1"
        return URL(string: "https://www.youtube.com/embed/\(videoID)?\(query)")
    }
}

#Preview {
    YouTubePlayerView(videoID: "dQw4w9WgXcQ", autoPlay: false)
        .aspectRatio(16 / 9, contentMode: .fit)
        .padding()
}
