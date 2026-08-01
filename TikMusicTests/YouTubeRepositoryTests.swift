import XCTest
@testable import TikMusic

/// Unit test cho YouTubeVideoRepository.
final class YouTubeRepositoryTests: XCTestCase {

    /// fetchVideos gọi 2 request (search + videos) và trộn thống kê.
    func testFetchVideosMakesSearchAndStatisticsRequests() async throws {
        let session = MockNetworkSession { request in
            let path = request.url?.path ?? ""
            if path.contains("/search") {
                return (TestFixtures.searchResponseData, HTTPTestResponse.make(statusCode: 200))
            }
            return (TestFixtures.videosResponseData, HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: "TEST_API_KEY")
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeVideoRepository(client: client, apiKeyProvider: provider)

        let page = try await repository.fetchVideos(category: .phonk, pageToken: nil)

        XCTAssertEqual(page.videos.count, 2)
        XCTAssertEqual(page.nextPageToken, "CAUQAA")

        // Video đầu tiên có thống kê từ endpoint videos.
        let first = page.videos.first
        XCTAssertEqual(first?.id, "abc123")
        XCTAssertEqual(first?.viewCount, 1_234_567)
        XCTAssertEqual(first?.duration, 253)
        XCTAssertEqual(first?.category, .phonk, "Giữ nguyên category")

        XCTAssertEqual(session.requestCount, 2, "Phải gọi search + videos")
    }

    /// searchVideos cũng trộn thống kê.
    func testSearchVideos() async throws {
        let session = MockNetworkSession { request in
            let path = request.url?.path ?? ""
            if path.contains("/search") {
                return (TestFixtures.searchResponseData, HTTPTestResponse.make(statusCode: 200))
            }
            return (TestFixtures.videosResponseData, HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: "TEST_API_KEY")
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeVideoRepository(client: client, apiKeyProvider: provider)

        let page = try await repository.searchVideos(query: "phonk music", pageToken: nil)

        XCTAssertEqual(page.videos.count, 2)
        XCTAssertEqual(page.videos.first?.viewCount, 1_234_567)
        XCTAssertNil(page.videos.first?.category, "Kết quả tìm kiếm không gán category")
    }

    /// fetchVideoDetail lấy chi tiết một video.
    func testFetchVideoDetail() async throws {
        let session = MockNetworkSession { _ in
            (TestFixtures.videosResponseData, HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: "TEST_API_KEY")
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeVideoRepository(client: client, apiKeyProvider: provider)

        let video = try await repository.fetchVideoDetail(videoID: "abc123")

        XCTAssertEqual(video.id, "abc123")
        XCTAssertEqual(video.viewCount, 1_234_567)
        XCTAssertEqual(video.duration, 253)
        XCTAssertEqual(session.requestCount, 1)
    }

    /// filterEmbeddable chỉ trả về những video có status.embeddable == true.
    func testFilterEmbeddable() async throws {
        let statusData = TestFixtures.videoStatusResponseData(embeddableIDs: ["abc123"])
        let session = MockNetworkSession { _ in
            (statusData, HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: "TEST_API_KEY")
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeVideoRepository(client: client, apiKeyProvider: provider)

        let embeddable = try await repository.filterEmbeddable(ids: ["abc123", "xyz999"])

        XCTAssertEqual(embeddable, ["abc123"], "Chỉ trả về video embeddable được")
        XCTAssertEqual(session.requestCount, 1)
    }

    /// Thiếu API Key → ném APIError.missingAPIKey.
    func testMissingAPIKeyThrows() async {        let session = MockNetworkSession { _ in
            (Data(), HTTPTestResponse.make(statusCode: 200))
        }

        // Bundle với placeholder (chưa cấu hình).
        let provider = makeProvider(withKey: APIKeyProvider.placeholder)
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeVideoRepository(client: client, apiKeyProvider: provider)

        do {
            _ = try await repository.fetchVideos(category: .phonk, pageToken: nil)
            XCTFail("Phải ném lỗi thiếu API Key")
        } catch let error as APIError {
            guard case .missingAPIKey = error else {
                return XCTFail("Sai loại lỗi: \(error)")
            }
            XCTAssertEqual(session.requestCount, 0, "Không được gọi mạng khi thiếu key")
        } catch {
            XCTFail("Sai loại lỗi: \(error)")
        }
    }

    // MARK: - Helpers

    /// Tạo APIKeyProvider với key chỉ định bằng cách dựng bundle test tạm.
    private func makeProvider(withKey key: String) -> APIKeyProvider {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>YOUTUBE_API_KEY</key>
            <string>\(key)</string>
        </dict>
        </plist>
        """
        try? plist.write(to: tempDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)

        let bundle = Bundle(url: tempDir)!
        return APIKeyProvider(bundle: bundle)
    }
}
