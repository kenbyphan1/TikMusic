import Foundation
import Network

/// Máy chủ HTTP tối thiểu chạy trên loopback (`127.0.0.1`), cổng ngẫu nhiên.
///
/// Mục đích: phục vụ trang nhúng YouTube từ một **origin HTTP thật**.
/// WKWebView tải trang từ `http://127.0.0.1:<port>/embed/<videoID>` → khi
/// iframe gọi YouTube, WebKit tự gắn header `Referer` hợp lệ → YouTube
/// chấp nhận cấu hình player (hết lỗi 153 / 152-4 "This video is not
/// available").
///
/// Lý do phải có server nội bộ: trên iOS, WKWebView không gửi `Referer`
/// khi nội dung được load từ origin không phải HTTP(S) thật (bundle,
/// custom scheme, `about:blank`, hoặc header gán tay bị WebKit bỏ qua).
final class EmbedServer {

    /// Instance dùng chung toàn app.
    static let shared = EmbedServer()

    /// Cổng đang lắng nghe (`0` nếu chưa sẵn sàng).
    private(set) var port: UInt16 = 0

    /// URL gốc của server, vd `http://127.0.0.1:12345`.
    var baseURL: URL? {
        guard port > 0 else { return nil }
        return URL(string: "http://127.0.0.1:\(port)")
    }

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.tikmusic.embed-server")
    private var isStarted = false

    private init() {}

    /// Khởi động server (an toàn gọi nhiều lần).
    func start() {
        guard !isStarted else { return }
        isStarted = true

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        // Chỉ lắng nghe trên loopback, không hở ra mạng ngoài.
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: "127.0.0.1",
            port: .any
        )

        do {
            listener = try NWListener(using: parameters)
        } catch {
            AppLogger.error("EmbedServer: không tạo được listener - \(error.localizedDescription)")
            return
        }

        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.port = self?.listener?.port?.rawValue ?? 0
                AppLogger.info("EmbedServer sẵn sàng tại cổng \(self?.port ?? 0)")
            case .failed(let error):
                AppLogger.error("EmbedServer lỗi: \(error.localizedDescription)")
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }

        listener?.start(queue: queue)
    }

    // MARK: - Xử lý kết nối

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(connection, buffer: Data())
    }

    /// Nhận dữ liệu cho tới khi đủ khối request (kết thúc bởi `\r\n\r\n`).
    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }

            if let error {
                AppLogger.error("EmbedServer receive lỗi: \(error.localizedDescription)")
                connection.cancel()
                return
            }

            var full = buffer
            if let data {
                full.append(data)
            }

            let headerEnd = full.range(of: Data("\r\n\r\n".utf8))
            if isComplete || headerEnd != nil {
                self.respond(to: full, connection: connection)
            } else if full.count > 16_384 {
                connection.cancel()
            } else {
                self.receive(connection, buffer: full)
            }
        }
    }

    // MARK: - Response

    private func respond(to requestData: Data, connection: NWConnection) {
        let request = String(data: requestData, encoding: .utf8) ?? ""
        let (status, body, contentType) = Self.buildResponse(for: request)
        let header = "HTTP/1.1 \(status)\r\n"
            + "Content-Type: \(contentType)\r\n"
            + "Content-Length: \(body.count)\r\n"
            + "Connection: close\r\n"
            + "\r\n"
        let response = header.data(using: .utf8)! + body

        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    /// Đọc request, trả về status, body và content type tương ứng.
    private static func buildResponse(for request: String) -> (Int, Data, String) {
        let lines = request.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard let requestLine = lines.first else {
            return Self.errorResponse(400, "Bad Request")
        }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2, parts[0] == "GET" else {
            return Self.errorResponse(405, "Method Not Allowed")
        }

        // Tách path và query.
        let rawPath = String(parts[1])
        let pathAndQuery = rawPath.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let path = String(pathAndQuery[0])
        var query: [String: String] = [:]
        if pathAndQuery.count > 1 {
            for item in pathAndQuery[1].split(separator: "&", omittingEmptySubsequences: false) {
                let kv = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                if kv.count == 2 {
                    query[String(kv[0])] = String(kv[1])
                }
            }
        }

        let components = path.split(separator: "/").map(String.init)
        guard components.count >= 2, components[0] == "embed" else {
            return Self.errorResponse(404, "Not Found")
        }

        let videoID = components[1]
        guard isValidVideoID(videoID) else {
            return Self.errorResponse(404, "Not Found")
        }

        let autoPlay = query["autoplay"] == "1"
        let startSeconds = Int(query["t"] ?? "") ?? 0

        let html = Self.playerHTML(videoID: videoID, autoPlay: autoPlay, startSeconds: startSeconds)
        return (200, Data(html.utf8), "text/html; charset=utf-8")
    }

    private static func errorResponse(_ code: Int, _ message: String) -> (Int, Data, String) {
        (code, Data(message.utf8), "text/plain; charset=utf-8")
    }

    // MARK: - HTML

    /// Trang nhúng iframe YouTube (được load từ origin HTTP thật).
    ///
    /// Dùng YouTube IFrame API để nhận sự kiện `onError` (mã 2, 5, 100,
    /// 101, 150) và gửi về app qua `window.webkit.messageHandlers.playerError`
    /// → giúp UI phát hiện video bị cấm nhúng và chạy Smart Fallback.
    /// Đồng thời hỗ trợ:
    /// - `t=<giây>`: bắt đầu phát từ vị trí (tiếp tục xem).
    /// - `window.webkit.messageHandlers.playerReady` khi player sẵn sàng.
    private static func playerHTML(videoID: String, autoPlay: Bool, startSeconds: Int) -> String {
        let autoplay = autoPlay ? "1" : "0"
        let startParam = startSeconds > 0 ? "start: \(startSeconds)," : ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <meta name="referrer" content="strict-origin-when-cross-origin">
        <style>
        html, body { margin: 0; padding: 0; background: #000; height: 100%; overflow: hidden; }
        #player { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
        </style>
        </head>
        <body>
        <div id="player"></div>
        <script>
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

        var player;
        function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
                videoId: '\(videoID)',
                playerVars: {
                    autoplay: \(autoplay),
                    playsinline: 1,
                    rel: 0,
                    controls: 1,
                    modestbranding: 1,
                    \(startParam)
                    origin: location.origin
                },
                events: {
                    onReady: function() {
                        if (window.webkit && window.webkit.messageHandlers &&
                            window.webkit.messageHandlers.playerReady) {
                            window.webkit.messageHandlers.playerReady.postMessage('ready');
                        }
                    },
                    onStateChange: function(event) {
                        // Phát (1) → gửi thời gian hiện tại định kỳ để app
                        // ghi nhận "tiếp tục xem".
                        if (event.data === 1) {
                            startTimeReport();
                        }
                    },
                    onError: function(event) {
                        if (window.webkit && window.webkit.messageHandlers &&
                            window.webkit.messageHandlers.playerError) {
                            window.webkit.messageHandlers.playerError.postMessage(event.data);
                        }
                    }
                }
            });
        }

        var timeReportTimer = null;
        function startTimeReport() {
            if (timeReportTimer) return;
            timeReportTimer = setInterval(function() {
                if (player && player.getCurrentTime &&
                    window.webkit && window.webkit.messageHandlers &&
                    window.webkit.messageHandlers.playerTime) {
                    window.webkit.messageHandlers.playerTime.postMessage(player.getCurrentTime());
                }
            }, 1000);
        }
        </script>
        </body>
        </html>
        """
    }

    /// ID video YouTube hợp lệ: 11 ký tự `[A-Za-z0-9_-]`.
    private static func isValidVideoID(_ id: String) -> Bool {
        guard id.count == 11 else { return false }
        return id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }
}
