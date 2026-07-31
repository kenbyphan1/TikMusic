# Kiến trúc TikMusic

Tài liệu mô tả kiến trúc tổng thể, luồng dữ liệu và các quy ước của ứng dụng
**TikMusic** — SwiftUI, MVVM + Clean Architecture.

---

## 1. Tổng quan

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation (SwiftUI)                                     │
│  Views ──► ViewModels (@Observable @MainActor)              │
│  + Theme, Components, PreviewContent                        │
├─────────────────────────────────────────────────────────────┤
│  Domain                                                     │
│  Entities (MusicVideo, Playlist, MusicCategory)             │
│  Repository protocols (Video / Playlist / Favorites)        │
│  UseCases (FetchVideos, SearchVideos, Playlist, Favorites)  │
├─────────────────────────────────────────────────────────────┤
│  Data                                                       │
│  YouTube DTOs + MusicVideoMapper ◄── YouTubeVideoRepository │
│  SwiftDataModels + SwiftData(Playlist/Favorites)Repository  │
│  APIKeyStore/APIKeyProvider, SearchHistoryStore             │
├─────────────────────────────────────────────────────────────┤
│  Core                                                       │
│  Networking (APIClient, RequestBuilder, retry, errors)      │
│  Cache (MemoryCache, DiskCache, ImageCache)                 │
│  DI (DependencyContainer)                                   │
│  Utility (AppLogger)                                        │
└─────────────────────────────────────────────────────────────┘
```

- **Presentation** không bao giờ import `Data` trực tiếp; chỉ dùng `Domain` qua use case + protocol.
- **Domain** thuần Swift, không phụ thuộc UIKit/SwiftUI/SwiftData/Foundation mạng.
- **Data** implement protocol của Domain, chịu trách nhiệm lấy/lưu dữ liệu.
- **Core** các tiện ích dùng chung, không phụ thuộc nghiệp vụ.

## 2. Dependency Injection

`TikMusicApp` khởi tạo **một lần duy nhất**:

- `ModelContainer` (SwiftData) → `DependencyContainer`.

`DependencyContainer` (Composition Root) dựng toàn bộ đồ thị:
APIClient → repositories → use cases → ViewModels dùng chung,
rồi được bơm vào SwiftUI Environment bằng `.environment(container)` trong `RootView`.

Các ViewModel không dùng chung (chi tiết video, chi tiết playlist) được tạo qua factory:
`container.makeVideoDetailViewModel(video:)`, `container.makePlaylistDetailViewModel(playlist:)`.

Mọi `@Observable` ViewModel là `@MainActor` — an toàn khi cập nhật UI.

## 3. Luồng dữ liệu (ví dụ: Trang chủ)

1. `HomeView` hiển thị → `.task(id: selectedCategory)` gọi `homeViewModel.reload()`.
2. `HomeViewModel` (Presentation) → `FetchVideosUseCase` (Domain) → `VideoRepositoryProtocol` (protocol).
3. `YouTubeVideoRepository` (Data):
   - Gọi `YouTubeEndpoint.search` → `YouTubeSearchResponseDTO`.
   - Map DTO → `MusicVideo` (thiếu thống kê).
   - Gọi `YouTubeEndpoint.videos` (part=snippet,contentDetails,statistics) → trộn lượt xem/thời lượng.
4. Trả `VideoPage` về; ViewModel cập nhật `state` (`.loading/.loaded/.empty/.error`); View render tương ứng.

## 4. Networking & Lỗi

- `APIEndpoint` protocol mô tả endpoint (baseURL, path, method, query, headers, body, timeout).
- `RequestBuilder` dựng `URLRequest` (percent-encode tự động).
- `APIClient` gửi qua `NetworkSession` (protocol — mock được):
  - Kiểm tra status 2xx; map 403 quota → `.quotaExceeded`; parse body lỗi chuẩn của Google.
  - **Retry** (với backoff) cho lỗi 5xx, 429, lỗi mạng; **không** retry lỗi 4xx/decode.
- `APIError` là `LocalizedError` — hiển thị được trực tiếp cho người dùng.

## 5. API Key

- **Build-time**: `Config/Config.xcconfig` → `$(YOUTUBE_API_KEY)` → `Info.plist`.
- **Runtime**: người dùng nhập trong Cài đặt → lưu **Keychain** (`APIKeyStore`), ưu tiên hơn build-time.
- Placeholder `YOUR_YOUTUBE_API_KEY` và chuỗi rỗng đều bị coi là "chưa cấu hình".
- `APIKeyProvider` là `@Observable` để UI phản ứng ngay khi key đổi.

## 6. Lưu trữ cục bộ (SwiftData)

Models: `PlaylistRecord` (cascade → `PlaylistItemRecord`), `FavoriteVideoRecord` (`@Attribute(.unique)`).

- `SwiftDataPlaylistRepository`: create/rename/delete/add/remove/setOrder, chống thêm trùng.
- `SwiftDataFavoritesRepository`: add/remove/removeAll/isFavorite, mới nhất trước.
- Cả hai là `@MainActor`, dùng `ModelContext.mainContext`.

Lịch sử tìm kiếm dùng `UserDefaults` (`SearchHistoryStore`, tối đa 10 mục).

## 7. Cache ảnh

`ImageCache` (Singleton, `@MainActor`):

1. RAM (`MemoryCache` countLimit 150) → 2. đĩa (`DiskCache`, SHA-256 filename, TTL 7 ngày) → 3. mạng.
- Dedupe các request đang tải dang dở cho cùng URL.
- `CachedAsyncImage` là view SwiftUI dùng cache này, hiển thị placeholder khi chưa có ảnh.

## 8. Navigation & Animation

- `HomeView`, `SearchView`, `FavoritesView` tự bọc `NavigationStack`.
- `HomeView` mở search qua `fullScreenCover`.
- Hero animation: `HeroTransition.swift` — iOS 18 dùng `matchedTransitionSource` + `.zoom`,
  iOS 17 tự fallback (mã luôn compile ở cả hai bản).

## 9. State & ViewState

`ViewState`: `.idle / .loading / .loaded / .empty / .error(String)` — dùng chung cho các màn hình tải dữ liệu.
View dùng `switch viewModel.state` để render skeleton / grid / empty / error tương ứng.

## 10. Quy ước code

- Ngôn ngữ: tiếng Việt (doc comment), tên symbol/func tiếng Anh.
- Struct cho value type; `final class @Observable @MainActor` cho ViewModel.
- Không hardcode hằng số thiết kế — dùng `AppTheme`.
- Mọi màn hình có `#Preview` dùng `PreviewData.container` (ModelContainer in-memory).
- `AppLogger` để log; không dùng `print` rải rác.
