import SwiftUI
import WebKit

/// Trình phát YouTube nhúng (embed) dựa trên WKWebView.
///
/// Trang embed được phục vụ từ `EmbedServer` (origin `http://127.0.0.1`)
/// nên WKWebView gửi đúng `Referer` — tránh lỗi 153/152-4. Khi video bị
/// chủ kênh cấm nhúng (mã lỗi 101/150), player gửi sự kiện về app qua
/// `playerError` để UI chạy Smart Fallback.
///
/// Hỗ trợ thêm:
/// - `isActive`: điều khiển play/pause qua JavaScript khi video đã load
///   (dùng cho feed Short để chỉ phát video đang hiển thị).
/// - `startSeconds`: bắt đầu phát từ vị trí xác định (tiếp tục xem).
struct YouTubePlayerView: UIViewRepresentable {

    /// ID video trên YouTube.
    let videoID: String

    /// Tự động phát khi hiển thị.
    var autoPlay: Bool = false

    /// Video có nên phát không (false → pause qua JS). Mặc định `true`.
    var isActive: Bool = true

    /// Vị trí bắt đầu phát (giây).
    var startSeconds: Int = 0

    /// Callback khi player gặp lỗi (mã lỗi YouTube: 2, 5, 100, 101, 150).
    var onPlayerError: ((Int) -> Void)?

    /// Callback khi player đã sẵn sàng phát.
    var onPlayerReady: (() -> Void)?

    /// Callback báo vị trí phát hiện tại (giây) — gửi định kỳ khi đang phát.
    var onTimeUpdate: ((Double) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "playerError")
        userContentController.add(context.coordinator, name: "playerReady")
        userContentController.add(context.coordinator, name: "playerTime")
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
        context.coordinator.onPlayerReady = onPlayerReady
        context.coordinator.onTimeUpdate = onTimeUpdate
        context.coordinator.load(
            videoID: videoID,
            autoPlay: autoPlay,
            isActive: isActive,
            startSeconds: startSeconds,
            into: webView
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Coordinator nhận sự kiện từ JavaScript player và điều khiển web view.
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        /// Video đã load gần nhất (tránh reload liên tục).
        private var loadedVideoID: String?
        private var loadedAutoPlay = false
        private var loadedIsActive = true
        private var loadedStartSeconds = 0

        /// Player đã sẵn sàng chưa (nhận `playerReady` từ JS).
        private var isPlayerReady = false

        /// Callback báo lỗi player (set từ updateUIView).
        var onPlayerError: ((Int) -> Void)?

        /// Callback báo player sẵn sàng.
        var onPlayerReady: (() -> Void)?

        /// Callback báo vị trí phát hiện tại.
        var onTimeUpdate: ((Double) -> Void)?

        func load(
            videoID: String,
            autoPlay: Bool,
            isActive: Bool,
            startSeconds: Int,
            into webView: WKWebView
        ) {
            let videoChanged = loadedVideoID != videoID
                || loadedAutoPlay != autoPlay
                || loadedStartSeconds != startSeconds

            if videoChanged {
                loadedVideoID = videoID
                loadedAutoPlay = autoPlay
                loadedStartSeconds = startSeconds
                loadedIsActive = isActive
                isPlayerReady = false
                loadURL(
                    videoID: videoID,
                    autoPlay: autoPlay,
                    startSeconds: startSeconds,
                    into: webView
                )
            } else if isActive != loadedIsActive {
                // Video đã load — chỉ cần play/pause qua JS.
                loadedIsActive = isActive
                setActive(isActive, into: webView)
            }
        }

        /// Load embed từ server nội bộ. Nếu server chưa sẵn sàng thì thử lại.
        private func loadURL(
            videoID: String,
            autoPlay: Bool,
            startSeconds: Int,
            into webView: WKWebView
        ) {
            guard let baseURL = EmbedServer.shared.baseURL else {
                // Server chưa mở xong cổng — thử lại sau một khoảng ngắn.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.loadURL(
                        videoID: videoID,
                        autoPlay: autoPlay,
                        startSeconds: startSeconds,
                        into: webView
                    )
                }
                return
            }

            var params: [String] = []
            if autoPlay { params.append("autoplay=1") }
            if startSeconds > 0 { params.append("t=\(startSeconds)") }

            let query = params.isEmpty ? "" : "?" + params.joined(separator: "&")
            let path = "/embed/\(videoID)\(query)"
            guard let url = URL(string: path, relativeTo: baseURL) else { return }
            webView.load(URLRequest(url: url))
        }

        /// Phát / tạm dừng video đã load qua JavaScript.
        private func setActive(_ active: Bool, into webView: WKWebView) {
            let command = active ? "playVideo()" : "pauseVideo()"
            webView.evaluateJavaScript("player.\(command)") { _, _ in }
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "playerError":
                guard let code = message.body as? Int else { return }
                AppLogger.info("YouTubePlayer báo lỗi \(code) cho video \(loadedVideoID ?? "")")
                onPlayerError?(code)
            case "playerReady":
                isPlayerReady = true
                // Nếu video cần phát khi hiển thị (isActive) thì phát sau khi ready.
                if loadedIsActive && !loadedAutoPlay, let webView = message.webView {
                    setActive(true, into: webView)
                }
                onPlayerReady?()
            case "playerTime":
                guard let seconds = message.body as? Double else { return }
                onTimeUpdate?(seconds)
            default:
                break
            }
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
