import XCTest
@testable import TikMusic

/// Mock VideoRepository dùng trong test.
final class MockVideoRepository: VideoRepositoryProtocol, @unchecked Sendable {
    var result: Result<VideoPage, Error> = .success(.empty)
    private(set) var receivedQuery: String?
    private(set) var receivedCategory: MusicCategory?
    private(set) var receivedPageToken: String?

    func fetchVideos(category: MusicCategory, pageToken: String?) async throws -> VideoPage {
        receivedCategory = category
        receivedPageToken = pageToken
        return try result.get()
    }

    func searchVideos(query: String, pageToken: String?) async throws -> VideoPage {
        receivedQuery = query
        receivedPageToken = pageToken
        return try result.get()
    }

    func fetchVideoDetail(videoID: String) async throws -> MusicVideo {
        throw APIError.invalidResponse
    }
}

/// In-memory PlaylistRepository dùng trong test.
final class InMemoryPlaylistRepository: PlaylistRepositoryProtocol, @unchecked Sendable {
    private var storage: [Playlist] = []

    func fetchPlaylists() throws -> [Playlist] { storage }

    func createPlaylist(name: String) throws -> Playlist {
        let playlist = Playlist(id: UUID(), name: name, createdAt: Date(), videos: [])
        storage.insert(playlist, at: 0)
        return playlist
    }

    func renamePlaylist(id: UUID, to newName: String) throws {
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return }
        storage[index].name = newName
    }

    func deletePlaylist(id: UUID) throws {
        storage.removeAll { $0.id == id }
    }

    func addVideo(_ video: MusicVideo, toPlaylist id: UUID) throws {
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return }
        if !storage[index].videos.contains(where: { $0.id == video.id }) {
            storage[index].videos.append(video)
        }
    }

    func removeVideo(videoID: String, fromPlaylist id: UUID) throws {
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return }
        storage[index].videos.removeAll { $0.id == videoID }
    }

    func setVideoOrder(_ videoIDs: [String], inPlaylist id: UUID) throws {
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return }
        let map = Dictionary(uniqueKeysWithValues: storage[index].videos.map { ($0.id, $0) })
        storage[index].videos = videoIDs.compactMap { map[$0] }
    }
}

/// In-memory FavoritesRepository dùng trong test.
final class InMemoryFavoritesRepository: FavoritesRepositoryProtocol, @unchecked Sendable {
    private var storage: [MusicVideo] = []

    func fetchFavorites() throws -> [MusicVideo] { storage }

    func isFavorite(videoID: String) throws -> Bool {
        storage.contains { $0.id == videoID }
    }

    func addFavorite(_ video: MusicVideo) throws {
        if !storage.contains(where: { $0.id == video.id }) {
            storage.insert(video, at: 0)
        }
    }

    func removeFavorite(videoID: String) throws {
        storage.removeAll { $0.id == videoID }
    }

    func removeAllFavorites() throws {
        storage.removeAll()
    }
}

/// Unit test cho các UseCase.
final class UseCaseTests: XCTestCase {

    private func makeVideo(id: String) -> MusicVideo {
        MusicVideo(id: id, title: "Bài \(id)", channelTitle: "Kênh")
    }

    // MARK: - SearchVideosUseCase

    func testSearchTrimsQuery() async throws {
        let repository = MockVideoRepository()
        repository.result = .success(VideoPage(videos: [makeVideo(id: "v1")], nextPageToken: nil))
        let useCase = SearchVideosUseCase(repository: repository)

        let page = try await useCase.execute(query: "  phonk  ", pageToken: nil)

        XCTAssertEqual(repository.receivedQuery, "phonk")
        XCTAssertEqual(page.videos.count, 1)
    }

    func testSearchEmptyQueryReturnsEmptyPage() async throws {
        let repository = MockVideoRepository()
        let useCase = SearchVideosUseCase(repository: repository)

        let page = try await useCase.execute(query: "   ", pageToken: nil)

        XCTAssertTrue(page.videos.isEmpty)
        XCTAssertNil(repository.receivedQuery, "Không được gọi repository với query rỗng")
    }

    // MARK: - FetchVideosUseCase

    func testFetchVideosPassesCategoryAndPageToken() async throws {
        let repository = MockVideoRepository()
        repository.result = .success(VideoPage(videos: [makeVideo(id: "v1")], nextPageToken: "TOKEN"))
        let useCase = FetchVideosUseCase(repository: repository)

        let page = try await useCase.execute(category: .lofi, pageToken: "TOKEN")

        XCTAssertEqual(repository.receivedCategory, .lofi)
        XCTAssertEqual(repository.receivedPageToken, "TOKEN")
        XCTAssertEqual(page.nextPageToken, "TOKEN")
    }

    // MARK: - PlaylistUseCase

    func testPlaylistCreateRenameDelete() throws {
        let repository = InMemoryPlaylistRepository()
        let useCase = PlaylistUseCase(repository: repository)

        let playlist = try useCase.create(name: "P1")
        XCTAssertEqual(playlist.name, "P1")

        try useCase.rename(id: playlist.id, to: "P1 mới")
        XCTAssertEqual(try useCase.fetchAll().first?.name, "P1 mới")

        try useCase.add(makeVideo(id: "v1"), to: playlist.id)
        XCTAssertEqual(try useCase.fetchAll().first?.videoCount, 1)

        try useCase.setOrder(["v1"], in: playlist.id)

        try useCase.delete(id: playlist.id)
        XCTAssertTrue(try useCase.fetchAll().isEmpty)
    }

    func testPlaylistCreateTrimsEmptyName() throws {
        let repository = InMemoryPlaylistRepository()
        let useCase = PlaylistUseCase(repository: repository)

        let playlist = try useCase.create(name: "   ")
        XCTAssertEqual(playlist.name, "Playlist mới", "Tên rỗng phải dùng tên mặc định")
    }

    // MARK: - FavoritesUseCase

    func testFavoritesAddRemove() throws {
        let repository = InMemoryFavoritesRepository()
        let useCase = FavoritesUseCase(repository: repository)

        try useCase.add(makeVideo(id: "v1"))
        XCTAssertTrue(try useCase.isFavorite(videoID: "v1"))

        try useCase.remove(videoID: "v1")
        XCTAssertFalse(try useCase.isFavorite(videoID: "v1"))
    }

    func testFavoritesDeduplicateAndRemoveAll() throws {
        let repository = InMemoryFavoritesRepository()
        let useCase = FavoritesUseCase(repository: repository)

        try useCase.add(makeVideo(id: "v1"))
        try useCase.add(makeVideo(id: "v1"))

        XCTAssertEqual(try useCase.fetchAll().count, 1)

        try useCase.add(makeVideo(id: "v2"))
        try useCase.removeAll()

        XCTAssertTrue(try useCase.fetchAll().isEmpty)
    }
}
