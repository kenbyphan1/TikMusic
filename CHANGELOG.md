# Changelog

## [1.0.0] — 2026-07-31

Dự án khởi tạo hoàn chỉnh trên Windows (không thể build tại chỗ — cần Xcode trên macOS).

### Thêm mới

**Kiến trúc & cấu hình**
- Xcode project (`TikMusic.xcodeproj`, objectVersion 77, `PBXFileSystemSynchronizedRootGroup`) với 2 targets: `TikMusic`, `TikMusicTests`.
- `Config/Config.xcconfig` chứa `YOUTUBE_API_KEY` (build-time), nhúng vào `Info.plist`.
- SwiftData `ModelContainer` (playlist, playlist items, yêu thích) tại `TikMusicApp`.
- `DependencyContainer` — DI composition root, bơm vào SwiftUI environment.

**Core**
- Networking: `APIEndpoint`, `RequestBuilder`, `NetworkSession`, `APIClient` (retry 5xx/429/network + backoff, parse lỗi chuẩn Google, `quotaExceeded`).
- Cache: `MemoryCache`, `DiskCache` (SHA-256 filename, TTL, expiry), `ImageCache` (RAM → đĩa → mạng, dedupe in-flight).
- `AppLogger`, `APIError` (LocalizedError).

**Domain**
- Entities: `MusicCategory` (13 chủ đề TikTok), `MusicVideo`, `VideoPage`, `Playlist`.
- Protocols: `VideoRepositoryProtocol`, `PlaylistRepositoryProtocol`, `FavoritesRepositoryProtocol`.
- UseCases: `FetchVideosUseCase`, `SearchVideosUseCase`, `PlaylistUseCase`, `FavoritesUseCase`.

**Data**
- YouTube DTO + `MusicVideoMapper` (`ISO8601DurationParser`, parse RFC3339 có/không fractional seconds).
- `YouTubeEndpoint` (search + videos), `YouTubeVideoRepository` (search → enrich thống kê).
- SwiftData repositories (playlist + favorites), `APIKeyStore` (Keychain), `APIKeyProvider`, `SearchHistoryStore`.

**Presentation**
- 5 tabs: Home, Search, Playlists, Favorites, Settings.
- ViewModels `@Observable @MainActor`: Home (phân trang, pull-to-refresh), Search (debounce 500ms, lịch sử, gợi ý), VideoDetail, PlaylistList/Detail, Favorites, Settings.
- Views & components: VideoCardView, CategoryCarouselView, CachedAsyncImage, Shimmer/Skeleton, EmptyState/ErrorState, YouTubePlayerView (WKWebView embed), hero animation (iOS 18 `.zoom`, fallback iOS 17).
- `AppTheme` (accent hồng TikTok, gradient, font), `ColorSchemeManager` (Dark/Light/System), preview data.

**Testing**
- 12 file unit test (~60 tests): networking, mapping, cache, repositories (SwiftData in-memory), use cases, history, category, API key.

### Sửa chữa (trong quá trình rà soát)
- Đổi `NumberFormatter` → `CompactNumberFormatter` (tránh shadow Foundation).
- `ColorSchemeManager` / `APIKeyProvider` bỏ `didSet` — dùng computed + stored cho `@Observable`.
- Sửa test retry dùng session đếm số lần gọi.
- `HomeViewModel.select` reset `state = .idle` khi đổi chủ đề (tránh hiển thị nhầm dữ liệu cũ).
- `Config.xcconfig` chỉ giữ `YOUTUBE_API_KEY` (tránh trùng build settings trong pbxproj).
- Test `P0D` chuyển sang `XCTAssertNil` (thời lượng 0 hợp lệ = unknown).
- `MockNetworkSession` đánh dấu `@unchecked Sendable`.
- Tạo `AppIcon.png` (1024×1024) cho assets catalog.

### Đã biết
- Chưa build/test được trên máy này (Windows, không có Swift/Xcode).
- App icon là hình vẽ đơn giản (gradient + nốt nhạc) — có thể thay sau.
