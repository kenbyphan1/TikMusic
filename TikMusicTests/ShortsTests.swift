import XCTest
@testable import TikMusic

/// Mock ShortRepository dùng trong test.
final class MockShortRepository: ShortRepositoryProtocol, @unchecked Sendable {
    var result: Result<ShortVideoPage, Error> = .success(.empty)
    var embeddableIDs: [String] = []
    var cachedVideos: [ShortVideo] = []
    private(set) var receivedQuery: String?
    private(set) var receivedPageToken: String?

    func fetchTrendingShorts(pageToken: String?) async throws -> ShortVideoPage {
        receivedPageToken = pageToken
        return try result.get()
    }

    func fetchNewestShorts(pageToken: String?) async throws -> ShortVideoPage {
        receivedPageToken = pageToken
        return try result.get()
    }

    func fetchByTag(_ tag: String, pageToken: String?) async throws -> ShortVideoPage {
        receivedQuery = tag
        receivedPageToken = pageToken
        return try result.get()
    }

    func searchShorts(query: String, pageToken: String?) async throws -> ShortVideoPage {
        receivedQuery = query
        receivedPageToken = pageToken
        return try result.get()
    }

    func prefetchNext(pageToken: String?) async throws -> ShortVideoPage {
        receivedPageToken = pageToken
        return try result.get()
    }

    func filterEmbeddable(ids: [String]) async throws -> [String] {
        Set(ids).intersection(embeddableIDs).map { $0 }
    }

    func cacheVideos(_ videos: [ShortVideo]) async throws {
        cachedVideos = videos
    }

    func loadCachedVideos() async throws -> [ShortVideo] {
        cachedVideos
    }
}

/// Unit test cho module Short: mapper, repository, history store, use case.
final class ShortsTests: XCTestCase {

    private func makeShort(id: String = "short1111111") -> ShortVideo {
        ShortVideo(
            id: id,
            title: "Dance Challenge",
            artist: "Dance Studio",
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"),
            videoURL: URL(string: "https://www.youtube.com/watch?v=\(id)")!,
            duration: 30,
            likes: 1_000,
            views: 100_000,
            comments: 200,
            shareCount: 50,
            createdAt: Date(),
            tags: ["shorts", "viral"],
            source: .remote
        )
    }

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

        return APIKeyProvider(bundle: Bundle(url: tempDir)!)
    }

    /// Videos response có id khớp với `shortsSearchResponseData` để test enrich.
    private var shortsVideosResponseData: Data {
        let json = """
        {
          "kind": "youtube#videoListResponse",
          "items": [
            {
              "id": "short1111111",
              "snippet": { "title": "Dance Challenge", "channelTitle": "Dance Studio" },
              "contentDetails": { "duration": "PT4M13S" },
              "statistics": { "viewCount": "1234567", "likeCount": "45678", "commentCount": "2345" }
            },
            {
              "id": "short2222222",
              "snippet": { "title": "Phonk Beat Short", "channelTitle": "Phonk Nation" },
              "contentDetails": { "duration": "PT0M45S" },
              "statistics": { "viewCount": "999", "likeCount": "10", "commentCount": "1" }
            }
          ]
        }
        """
        return Data(json.utf8)
    }

    // MARK: - ShortVideoMapper

    func testShortFromSearchItem() throws {
        let response = try JSONDecoder().decode(YouTubeSearchResponseDTO.self, from: TestFixtures.shortsSearchResponseData)
        let item = try XCTUnwrap(response.items?.first)

        let short = try XCTUnwrap(ShortVideoMapper.short(from: item))

        XCTAssertEqual(short.id, "short1111111")
        XCTAssertEqual(short.title, "Dance Challenge #shorts #viral")
        XCTAssertEqual(short.artist, "Dance Studio")
        XCTAssertEqual(short.thumbnailURL?.absoluteString, "https://i.ytimg.com/vi/short1111111/mqdefault.jpg")
        XCTAssertTrue(short.tags.contains("shorts"), "Phải trích được hashtag từ tiêu đề")
        XCTAssertTrue(short.tags.contains("trending"), "Phải trích được hashtag từ mô tả")
        XCTAssertEqual(short.source, .remote)
    }

    func testShortMissingVideoIdReturnsNil() throws {
        let json = """
        {
          "kind": "youtube#searchResult",
          "id": { "kind": "youtube#channel", "channelId": "UC123" },
          "snippet": { "title": "Kênh", "channelTitle": "Kênh" }
        }
        """
        let item = try JSONDecoder().decode(YouTubeSearchItemDTO.self, from: Data(json.utf8))

        XCTAssertNil(ShortVideoMapper.short(from: item))
    }

    func testMergingStatistics() throws {
        let response = try JSONDecoder().decode(YouTubeVideosResponseDTO.self, from: TestFixtures.videosResponseData)
        let item = try XCTUnwrap(response.items?.first)

        let short = makeShort()
        let merged = ShortVideoMapper.mergingStatistics(from: item, into: short)

        XCTAssertEqual(merged.views, 1_234_567)
        XCTAssertEqual(merged.likes, 45_678)
        XCTAssertEqual(merged.comments, 2_345)
        XCTAssertEqual(merged.duration, 253)
        XCTAssertEqual(merged.id, short.id)
        XCTAssertEqual(merged.tags, short.tags)
    }

    func testShortAsMusicVideo() {
        let short = makeShort()

        let video = short.asMusicVideo

        XCTAssertEqual(video.id, short.id)
        XCTAssertEqual(video.channelTitle, "Dance Studio")
        XCTAssertEqual(video.viewCount, 100_000)
    }

    // MARK: - YouTubeShortRepository

    func testFetchTrendingShortsMakesSearchAndStatisticsRequests() async throws {
        let session = MockNetworkSession { request in
            let path = request.url?.path ?? ""
            if path.contains("/search") {
                return (TestFixtures.shortsSearchResponseData, HTTPTestResponse.make(statusCode: 200))
            }
            return (shortsVideosResponseData, HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: "TEST_API_KEY")
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeShortRepository(
            client: client,
            apiKeyProvider: provider,
            maxResultsPerPage: 15
        )

        let page = try await repository.fetchTrendingShorts(pageToken: nil)

        XCTAssertEqual(page.videos.count, 2)
        XCTAssertEqual(page.nextPageToken, "SHORTS_NEXT")

        // Video đầu tiên có thống kê từ endpoint videos.
        let first = page.videos.first
        XCTAssertEqual(first?.id, "short1111111")
        XCTAssertEqual(first?.views, 1_234_567)
        XCTAssertEqual(first?.duration, 253)

        XCTAssertEqual(session.requestCount, 2, "Phải gọi search + videos")
    }

    func testShortsSearchEndpointHasDurationAndEmbeddableParams() async throws {
        var capturedURL: URL?
        let session = MockNetworkSession { request in
            capturedURL = request.url
            return (TestFixtures.shortsSearchResponseData, HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: "TEST_API_KEY")
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeShortRepository(client: client, apiKeyProvider: provider)

        _ = try await repository.searchShorts(query: "phonk", pageToken: nil)

        let url = try XCTUnwrap(capturedURL)
        let query = url.query ?? ""
        XCTAssertTrue(query.contains("videoDuration=short"), "Phải lọc video ngắn")
        XCTAssertTrue(query.contains("videoEmbeddable=true"), "Phải lọc video embeddable được")
        XCTAssertTrue(query.contains("q=phonk"))
    }

    func testFetchByTagDropsHashPrefix() async throws {
        var capturedURL: URL?
        let session = MockNetworkSession { request in
            capturedURL = request.url
            return (TestFixtures.shortsSearchResponseData, HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: "TEST_API_KEY")
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeShortRepository(client: client, apiKeyProvider: provider)

        _ = try await repository.fetchByTag("#phonk", pageToken: nil)

        let url = try XCTUnwrap(capturedURL)
        XCTAssertTrue((url.query ?? "").contains("q=phonk"), "Phải bỏ dấu # trong tag")
    }

    func testShortsCacheSaveAndLoad() throws {
        let store = ShortCacheStore(store: JSONFileStore(inMemory: "test-shorts-cache.json"))
        store.save([makeShort()])

        let loaded = store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, "short1111111")
    }

    func testShortCacheDeduplicates() throws {
        let store = ShortCacheStore(store: JSONFileStore(inMemory: "test-shorts-cache-dedupe.json"))
        store.save([makeShort()])
        store.save([makeShort(id: "short2222222")])

        XCTAssertEqual(store.load().count, 2)
    }

    func testShortRepositoryMissingAPIKeyThrows() async {
        let session = MockNetworkSession { _ in
            (Data(), HTTPTestResponse.make(statusCode: 200))
        }

        let provider = makeProvider(withKey: APIKeyProvider.placeholder)
        let client = APIClient(session: session, maxRetries: 0)
        let repository = YouTubeShortRepository(client: client, apiKeyProvider: provider)

        do {
            _ = try await repository.fetchTrendingShorts(pageToken: nil)
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

    // MARK: - ShortHistoryStore

    func testHistoryRecordAndOrder() throws {
        let store = ShortHistoryStore(store: JSONFileStore(inMemory: "test-history.json"))
        let a = makeShort(id: "short1111111")
        let b = makeShort(id: "short2222222")

        store.record(short: a, seconds: 10)
        store.record(short: b, seconds: 5)

        let recent = store.recentEntries
        XCTAssertEqual(recent.map(\.id), ["short2222222", "short1111111"], "Mới nhất phải đứng đầu")
        XCTAssertEqual(store.lastPlayedSeconds(id: "short1111111"), 10)
    }

    func testHistoryDeduplicates() throws {
        let store = ShortHistoryStore(store: JSONFileStore(inMemory: "test-history-dedupe.json"))
        let a = makeShort(id: "short1111111")

        store.record(short: a, seconds: 10)
        store.record(short: a, seconds: 25)

        XCTAssertEqual(store.recentEntries.count, 1)
        XCTAssertEqual(store.lastPlayedSeconds(id: "short1111111"), 25)
    }

    func testHistoryContinueWatching() throws {
        let store = ShortHistoryStore(store: JSONFileStore(inMemory: "test-history-continue.json"))
        let a = makeShort(id: "short1111111")
        let b = makeShort(id: "short2222222")

        // a đã xem tới giây 30 (chưa xong), b mới xem 0 giây.
        store.record(short: a, seconds: 30)
        store.record(short: b, seconds: 0)

        let continuing = store.continueWatchingEntries
        XCTAssertEqual(continuing.map(\.id), ["short1111111"], "Chỉ những video chưa xem hết mới tiếp tục xem")
    }

    func testHistoryUpdateProgress() throws {
        let store = ShortHistoryStore(store: JSONFileStore(inMemory: "test-history-progress.json"))
        let a = makeShort(id: "short1111111")

        store.record(short: a, seconds: 10)
        store.updateProgress(id: "short1111111", seconds: 45)

        XCTAssertEqual(store.lastPlayedSeconds(id: "short1111111"), 45)
    }

    func testHistoryClear() throws {
        let store = ShortHistoryStore(store: JSONFileStore(inMemory: "test-history-clear.json"))
        store.record(short: makeShort(), seconds: 10)

        store.clear()

        XCTAssertTrue(store.recentEntries.isEmpty)
    }

    // MARK: - ShortsUseCase

    func testUseCaseFetchesByMode() async throws {
        let repository = MockShortRepository()
        repository.result = .success(ShortVideoPage(videos: [makeShort()], nextPageToken: "TOKEN"))
        let useCase = ShortsUseCase(repository: repository)

        let trending = try await useCase.fetch(mode: .trending, pageToken: nil)
        XCTAssertEqual(trending.videos.count, 1)
        XCTAssertEqual(trending.nextPageToken, "TOKEN")

        _ = try await useCase.fetch(mode: .search("phonk"), pageToken: "TOKEN")
        XCTAssertEqual(repository.receivedQuery, "phonk")
        XCTAssertEqual(repository.receivedPageToken, "TOKEN")
    }

    func testUseCaseModeTitles() {
        XCTAssertEqual(ShortsFeedMode.trending.title, "Trending")
        XCTAssertEqual(ShortsFeedMode.newest.title, "Mới nhất")
        XCTAssertEqual(ShortsFeedMode.tag("phonk").title, "#phonk")
        XCTAssertEqual(ShortsFeedMode.search("abc").title, "abc")
    }

    func testUseCaseCacheRoundTrip() async throws {
        let repository = MockShortRepository()
        let useCase = ShortsUseCase(repository: repository)

        try await useCase.cacheVideos([makeShort()])
        XCTAssertEqual(repository.cachedVideos.count, 1)

        let loaded = try await useCase.loadCachedVideos()
        XCTAssertEqual(loaded.count, 1)
    }
}
