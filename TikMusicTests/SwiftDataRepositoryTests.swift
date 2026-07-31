import XCTest
@testable import TikMusic

/// Unit test cho FilePlaylistRepository và FileFavoritesRepository
/// sử dụng JSONFileStore in-memory.
final class FileRepositoryTests: XCTestCase {

    private func makePlaylistRepository() -> FilePlaylistRepository {
        FilePlaylistRepository(store: JSONFileStore(inMemory: "test-playlists-\(UUID().uuidString).json"))
    }

    private func makeFavoritesRepository() -> FileFavoritesRepository {
        FileFavoritesRepository(store: JSONFileStore(inMemory: "test-favorites-\(UUID().uuidString).json"))
    }

    private func makeVideo(id: String, title: String = "Bài hát test") -> MusicVideo {
        MusicVideo(
            id: id,
            title: title,
            channelTitle: "Kênh test",
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/\(id)/mqdefault.jpg"),
            viewCount: 1_000
        )
    }

    // MARK: - Playlist

    @MainActor
    func testCreateAndFetchPlaylist() throws {
        let repository = makePlaylistRepository()

        let playlist = try repository.createPlaylist(name: "Nhạc yêu thích")

        let fetched = try repository.fetchPlaylists()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, playlist.id)
        XCTAssertEqual(fetched.first?.name, "Nhạc yêu thích")
    }

    @MainActor
    func testRenamePlaylist() throws {
        let repository = makePlaylistRepository()

        let playlist = try repository.createPlaylist(name: "Cũ")
        try repository.renamePlaylist(id: playlist.id, to: "Mới")

        XCTAssertEqual(try repository.fetchPlaylists().first?.name, "Mới")
    }

    @MainActor
    func testDeletePlaylistRemovesItems() throws {
        let repository = makePlaylistRepository()

        let playlist = try repository.createPlaylist(name: "Playlist")
        try repository.addVideo(makeVideo(id: "v1"), toPlaylist: playlist.id)

        try repository.deletePlaylist(id: playlist.id)

        XCTAssertTrue(try repository.fetchPlaylists().isEmpty)
    }

    @MainActor
    func testAddVideoToPlaylist() throws {
        let repository = makePlaylistRepository()

        let playlist = try repository.createPlaylist(name: "P1")
        try repository.addVideo(makeVideo(id: "v1"), toPlaylist: playlist.id)
        try repository.addVideo(makeVideo(id: "v2"), toPlaylist: playlist.id)

        let fetched = try repository.fetchPlaylists().first
        XCTAssertEqual(fetched?.videoCount, 2)
        XCTAssertEqual(fetched?.videos.first?.title, "Bài hát test")
    }

    @MainActor
    func testAddVideoDeduplicates() throws {
        let repository = makePlaylistRepository()

        let playlist = try repository.createPlaylist(name: "P1")
        try repository.addVideo(makeVideo(id: "v1"), toPlaylist: playlist.id)
        try repository.addVideo(makeVideo(id: "v1"), toPlaylist: playlist.id)

        XCTAssertEqual(try repository.fetchPlaylists().first?.videoCount, 1)
    }

    @MainActor
    func testRemoveVideoFromPlaylist() throws {
        let repository = makePlaylistRepository()

        let playlist = try repository.createPlaylist(name: "P1")
        try repository.addVideo(makeVideo(id: "v1"), toPlaylist: playlist.id)
        try repository.addVideo(makeVideo(id: "v2"), toPlaylist: playlist.id)

        try repository.removeVideo(videoID: "v1", fromPlaylist: playlist.id)

        let videos = try repository.fetchPlaylists().first?.videos ?? []
        XCTAssertEqual(videos.map(\.id), ["v2"])
    }

    @MainActor
    func testSetVideoOrder() throws {
        let repository = makePlaylistRepository()

        let playlist = try repository.createPlaylist(name: "P1")
        try repository.addVideo(makeVideo(id: "v1", title: "A"), toPlaylist: playlist.id)
        try repository.addVideo(makeVideo(id: "v2", title: "B"), toPlaylist: playlist.id)
        try repository.addVideo(makeVideo(id: "v3", title: "C"), toPlaylist: playlist.id)

        // Sắp lại: v3, v1, v2.
        try repository.setVideoOrder(["v3", "v1", "v2"], inPlaylist: playlist.id)

        let order = try repository.fetchPlaylists().first?.videos.map(\.id) ?? []
        XCTAssertEqual(order, ["v3", "v1", "v2"])
    }

    // MARK: - Favorites

    @MainActor
    func testAddAndFetchFavorite() throws {
        let repository = makeFavoritesRepository()

        try repository.addFavorite(makeVideo(id: "v1"))
        try repository.addFavorite(makeVideo(id: "v2"))

        let favorites = try repository.fetchFavorites()
        XCTAssertEqual(favorites.count, 2)
        XCTAssertTrue(try repository.isFavorite(videoID: "v1"))
        XCTAssertFalse(try repository.isFavorite(videoID: "missing"))
    }

    @MainActor
    func testAddFavoriteDeduplicates() throws {
        let repository = makeFavoritesRepository()

        try repository.addFavorite(makeVideo(id: "v1"))
        try repository.addFavorite(makeVideo(id: "v1"))

        XCTAssertEqual(try repository.fetchFavorites().count, 1)
    }

    @MainActor
    func testRemoveFavorite() throws {
        let repository = makeFavoritesRepository()

        try repository.addFavorite(makeVideo(id: "v1"))
        try repository.removeFavorite(videoID: "v1")

        XCTAssertTrue(try repository.fetchFavorites().isEmpty)
    }

    @MainActor
    func testRemoveAllFavorites() throws {
        let repository = makeFavoritesRepository()

        try repository.addFavorite(makeVideo(id: "v1"))
        try repository.addFavorite(makeVideo(id: "v2"))
        try repository.removeAllFavorites()

        XCTAssertTrue(try repository.fetchFavorites().isEmpty)
    }

    @MainActor
    func testFavoriteFetchOrderNewestFirst() throws {
        let repository = makeFavoritesRepository()

        // Thêm tuần tự → v2 mới hơn (fetch trả về mới nhất trước).
        try repository.addFavorite(makeVideo(id: "v1"))
        Thread.sleep(forTimeInterval: 0.01)
        try repository.addFavorite(makeVideo(id: "v2"))

        let favorites = try repository.fetchFavorites()
        XCTAssertEqual(favorites.first?.id, "v2")
    }
}
