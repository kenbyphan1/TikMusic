import SwiftUI
import WebKit

/// Trình phát YouTube nhúng (embed) dựa trên WKWebView.
///
/// Không cần SDK của YouTube. Dùng một trang HTML proxy nội bộ với
/// `baseURL` là origin HTTPS hợp lệ để WKWebView gửi đúng `Referer`
/// mà YouTube yêu cầu — tránh lỗi 153 "Video player configuration error"
/// và 152-4 "This video is not available" trên iOS
/// (WebView không gửi Referer khi origin không phải HTTPS).
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

        let html = Self.playerHTML(videoID: videoID, autoPlay: autoPlay)
        // baseURL là origin youtube.com thật → WKWebView gửi Referer hợp lệ.
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))

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

    /// Tạo HTML proxy nhúng iframe YouTube.
    ///
    /// Quan trọng: iframe phải trỏ thẳng vào `www.youtube.com/embed/...`
    /// (KHÔNG phải youtube-nocookie.com) và KHÔNG kèm tham số `origin`
    /// hay `enablejsapi`. `baseURL` khi load phải là origin `https://www.youtube.com`
    /// thật — nhờ đó WKWebView gửi đúng `Referer`, YouTube chấp nhận
    /// cấu hình player (hết lỗi 153/152-4).
    private static func playerHTML(videoID: String, autoPlay: Bool) -> String {
        let autoplay = autoPlay ? "1" : "0"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <meta name="referrer" content="strict-origin-when-cross-origin">
        <style>
        html, body { margin: 0; padding: 0; background: transparent; height: 100%; overflow: hidden; }
        #player { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
        </style>
        </head>
        <body>
        <iframe
          id="player"
          frameborder="0"
          allowfullscreen
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          referrerpolicy="strict-origin-when-cross-origin"
          src="https://www.youtube.com/embed/\(videoID)?autoplay=\(autoplay)&playsinline=1&rel=0&modestbranding=1&controls=1"
        ></iframe>
        </body>
        </html>
        """
    }
}

#Preview {
    YouTubePlayerView(videoID: "dQw4w9WgXcQ", autoPlay: false)
        .aspectRatio(16 / 9, contentMode: .fit)
        .padding()
}
