# Nhật ký tiến độ — TikMusic

> Nhật ký ghi lại quá trình dựng ứng dụng iOS **TikMusic** trong thư mục
> `D:\phan mem tong hop nhac` trên **Windows** (không có Xcode/Swift/Git).

---

## Bối cảnh & hạn chế môi trường

- **Máy Windows**: không có Xcode, Swift toolchain, `git` → **không thể build / test / commit** tại chỗ.
- Mục tiêu: sinh ra một **Xcode project hoàn chỉnh**, source đầy đủ, chỉ cần mở bằng Xcode 16+
  trên macOS, thêm **YouTube Data API Key** là **build + chạy + test** được.
- Toàn bộ correctness được đảm bảo bằng **rà soát tĩnh** (đọc lại từng file, đối chiếu API).

---

## Các giai đoạn đã hoàn thành

### G1. Nền móng & cấu hình
- Tạo cây thư mục, `Config/Config.xcconfig` (`YOUTUBE_API_KEY`), `Info.plist` (đọc `$(YOUTUBE_API_KEY)`),
  `Assets.xcassets` (AppIcon + AccentColor), `.gitignore`, `project.pbxproj`, scheme `TikMusic.xcscheme`.

### G2. Core
- Networking: `HTTPMethod`, `APIError`, `APIEndpoint`, `RequestBuilder`, `NetworkSession`, `APIClient`
  (decode, retry 5xx/429/network + backoff, parse lỗi chuẩn Google, quotaExceeded), `NetworkLogger`, `AppLogger`.
- Cache: `MemoryCache`, `DiskCache` (SHA-256, TTL), `ImageCache` (RAM → đĩa → mạng, dedupe in-flight).
- DI: `DependencyContainer` (composition root, `@Observable @MainActor`).

### G3. Domain
- Entities: `MusicCategory` (13 chủ đề: TikTok Viral, Trending, Remix, Mashup, Phonk, Chill, Sad, EDM,
  Nightcore, KPOP, USUK, Anime, Lofi — kèm query/symbol/gradient), `MusicVideo`, `VideoPage`, `Playlist`.
- Repository protocols: `VideoRepositoryProtocol`, `PlaylistRepositoryProtocol`, `FavoritesRepositoryProtocol`.
- UseCases: `FetchVideosUseCase`, `SearchVideosUseCase` (trim/empty), `PlaylistUseCase`, `FavoritesUseCase`.

### G4. Data
- YouTube DTO (`YouTubeVideoDTO`), `MusicVideoMapper` (map + `ISO8601DurationParser` + parse ngày RFC3339).
- `YouTubeEndpoint`, `YouTubeVideoRepository` (search → enrich thống kê).
- `SwiftDataModels` (`PlaylistRecord`, `PlaylistItemRecord`, `FavoriteVideoRecord`),
  `SwiftDataPlaylistRepository`, `SwiftDataFavoritesRepository`, `SearchHistoryStore` (tối đa 10).
- `APIKeyStore` (Keychain), `APIKeyProvider` (runtime ưu tiên > build; placeholder bị bỏ qua).

### G5. Presentation
- Theme: `ColorSchemeManager` (Dark/Light/System), `AppTheme` (accent hồng TikTok, gradient, font, `CompactNumberFormatter`).
- ViewModels `@Observable @MainActor`: `HomeViewModel` (phân trang, pull-to-refresh, đổi chủ đề),
  `SearchViewModel` (debounce 500ms, lịch sử, gợi ý), `VideoDetailViewModel`, `PlaylistListViewModel`,
  `PlaylistDetailViewModel`, `FavoritesViewModel`, `SettingsViewModel`.
- Components: `ShimmerView`/`Skeleton`, `GlassCard`, `StateViews`, `CachedAsyncImage`, `HeroTransition`, `Formatting`.
- Views: `HomeView` (+`VideoCardView`, `CategoryCarouselView`), `SearchView`, `VideoDetailView`
  (+`YouTubePlayerView`), `PlaylistListView`/`CreatePlaylistView`/`PlaylistDetailView`, `FavoritesView`,
  `SettingsView`/`APIKeyView`, `MainTabView`, `RootView`.
- App: `TikMusicApp` (ModelContainer + DI), `PreviewData`.

### G6. Unit tests
- 12 file: `APIClientTests`, `RequestBuilderTests`, `DTOMappingTests`, `YouTubeRepositoryTests`,
  `CacheTests`, `SwiftDataRepositoryTests`, `SearchHistoryStoreTests`, `UseCaseTests`,
  `MusicCategoryTests`, `APIKeyProviderTests` + `TestFixtures`, `TestHelpers`.

### G7. Rà soát tĩnh & sửa lỗi
- Đọc lại **toàn bộ** file source + test + pbxproj để bắt lỗi compile/API tiềm ẩn.
- Các vấn đề phát hiện & đã sửa:
  1. `NumberFormatter` (đã đổi thành `CompactNumberFormatter`).
  2. `didSet` trong class `@Observable` (ColorSchemeManager, APIKeyProvider) → chuyển computed + stored.
  3. Test retry sai logic (dùng session đếm số lần gọi).
  4. `HomeViewModel.select` không reset state → **hiển thị sai dữ liệu chủ đề cũ** (đã reset `.idle`).
  5. `Config.xcconfig` trùng lặp build settings với pbxproj (đã bỏ bớt).
  6. Test `P0D` sai kỳ vọng (đổi sang `XCTAssertNil`).
  7. `MockNetworkSession` thiếu `@unchecked Sendable`.

### G8. Icon & tài liệu
- Tạo `AppIcon.png` 1024×1024 (gradient hồng→tím→xanh + nốt nhạc trắng) bằng System.Drawing.
- Viết `README.md`, `INSTALL.md`, `ARCHITECTURE.md`, `TESTING.md`, `CHANGELOG.md`, `TODO.md`, `LICENSE`, `PROGRESS.md`.

---

## Trạng thái hiện tại

- [x] Toàn bộ source + Xcode project sinh xong.
- [x] Rà soát tĩnh toàn bộ code (không phát hiện lỗi chặn).
- [x] App icon + tài liệu hoàn tất.
- [ ] Build lần đầu trên macOS/Xcode — **chưa thực hiện được** (Windows).
- [ ] Chạy unit test — **chưa thực hiện được** (Windows).
- [ ] Git init & commit — **chưa thực hiện được** (không có git trên máy).

## Việc cần làm khi chuyển sang macOS

1. Mở `TikMusic.xcodeproj` bằng Xcode 16+.
2. Cấu hình API Key (`Config/Config.xcconfig` hoặc nhập runtime trong Cài đặt).
3. Build (`Cmd+R`) — sửa lỗi nếu có.
4. Chạy test (`Cmd+U`) — sửa test fail nếu có.
5. Nếu muốn dùng git: cài Git, `git init` (đã có `.gitignore`), commit lần đầu.

## Ghi chú

- Các quyết định thiết kế chi tiết được ghi trong doc comment của từng file (tiếng Việt).
- `Config/Config.xcconfig` đang bị `.gitignore` — nếu muốn commit key cho team, bỏ dòng ignore tương ứng.
