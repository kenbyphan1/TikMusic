import SwiftUI
import WebKit

/// Trình phát YouTube nhúng (embed) dựa trên WKWebView.
///
/// Trang embed được phục vụ từ `EmbedServer` (origin `http://127.0.0.1`)
/// nên WKWebView gửi đúng `Referer` — tránh lỗi 153/152-4. Khi video bị
/// chủ kênh cấm nhúng (mã lỗi 101/150), player gửi sự kiện về app qua
/// `playerError` để UI chạy Smart Fallback.
struct YouTubePlayerView: UIViewRepresentable {

    /// ID video trên YouTube.
    let videoID: String

    /// Tự động phát khi hiển thị.
    var autoPlay: Bool = false

    /// Callback khi player gặp lỗi (mã lỗi YouTube: 2, 5, 100, 101, 150).
    var onPlayerError: ((Int) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "playerError")
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onPlayerError = onPlayerError
        context.coordinator.load(videoID: videoID, autoPlay: autoPlay, into: webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Coordinator nhận sự kiện từ JavaScript player và điều khiển web view.
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        /// Video đã load gần nhất (tránh reload liên tục).
        private var loadedVideoID: String?
        private var loadedAutoPlay = false

        /// Callback báo lỗi player (set từ updateUIView).
        var onPlayerError: ((Int) -> Void)?

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

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "playerError",
                  let code = message.body as? Int else { return }
            AppLogger.info("YouTubePlayer báo lỗi \(code) cho video \(loadedVideoID ?? "")")
            onPlayerError?(code)
        }

        // MARK: - WKNavigationDelegate

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
