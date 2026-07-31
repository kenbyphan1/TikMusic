import SwiftUI
import WebKit

/// Trình phát YouTube nhúng (embed) dựa trên WKWebView.
///
/// Không cần SDK của YouTube. Trang embed được phục vụ từ `EmbedServer`
/// chạy trên `http://127.0.0.1:<port>` — một origin HTTP thật — nên
/// WKWebView tự gắn header `Referer` hợp lệ khi iframe gọi YouTube.
/// Nhờ đó tránh được lỗi 153 "Video player configuration error" và
/// 152-4 "This video is not available" trên iOS.
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
        context.coordinator.load(videoID: videoID, autoPlay: autoPlay, into: webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Coordinator chịu trách nhiệm (re)load video và chờ server sẵn sàng.
    final class Coordinator: NSObject, WKNavigationDelegate {
        /// Video đã load gần nhất (tránh reload liên tục).
        private var loadedVideoID: String?
        private var loadedAutoPlay = false

        func load(videoID: String, autoPlay: Bool, into webView: WKWebView) {
            guard loadedVideoID != videoID || loadedAutoPlay != autoPlay else { return }
            loadedVideoID = videoID
            loadedAutoPlay = autoPlay
            loadURL(videoID: videoID, autoPlay: autoPlay, into: webView)
        }

        /// Load embed từ server nội bộ. Nếu server chưa sẵn sàng thì thử lại.
        private func loadURL(videoID: String, autoPlay: Bool, into webView: WKWebView) {
            guard let baseURL = EmbedServer.shared.baseURL else {
                // Server chưa mở xong cổng — thử lại sau một khoảng ngắn.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.loadURL(videoID: videoID, autoPlay: autoPlay, into: webView)
                }
                return
            }

            let autoplayParam = autoPlay ? "autoplay=1" : ""
            let path = "/embed/\(videoID)" + (autoplayParam.isEmpty ? "" : "?\(autoplayParam)")
            guard let url = URL(string: path, relativeTo: baseURL) else { return }
            webView.load(URLRequest(url: url))
        }

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
