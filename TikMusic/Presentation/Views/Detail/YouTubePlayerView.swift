import SwiftUI
import WebKit

/// Trình phát YouTube nhúng (embed) dựa trên WKWebView.
///
/// Không cần SDK của YouTube — chỉ cần URL embed chuẩn:
/// `https://www.youtube.com/embed/<id>?playsinline=1`.
struct YouTubePlayerView: UIViewRepresentable {

    /// ID video trên YouTube.
    let videoID: String

    /// Tự động phát khi hiển thị.
    var autoPlay: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        var components = URLComponents(string: "https://www.youtube.com/embed/\(videoID)")
        components?.queryItems = [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "rel", value: "0"),
        ]
        if autoPlay {
            components?.queryItems?.append(URLQueryItem(name: "autoplay", value: "1"))
        }

        guard let url = components?.url else { return }

        // Chỉ load lại khi URL khác để tránh reload không cần thiết.
        if webView.url?.absoluteString != url.absoluteString {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Coordinator theo dõi trạng thái điều hướng của web view.
    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            AppLogger.error("YouTubePlayer load lỗi: \(error.localizedDescription)")
        }
    }
}

#Preview {
    YouTubePlayerView(videoID: "dQw4w9WgXcQ", autoPlay: false)
        .aspectRatio(16 / 9, contentMode: .fit)
        .padding()
}
