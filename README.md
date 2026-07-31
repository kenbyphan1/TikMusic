# TikMusic

Ứng dụng iOS **tổng hợp video nhạc theo chủ đề TikTok** — sử dụng **YouTube Data API v3**, viết bằng **SwiftUI** theo kiến trúc **MVVM + Clean Architecture**.

> Dự án được sinh hoàn chỉnh (source + Xcode project) trên môi trường Windows, không thể build/test tại chỗ. **Vui lòng mở bằng Xcode trên macOS để build, chạy và chạy unit test** (xem [INSTALL.md](INSTALL.md)).

---

## Tính năng

- **5 tab chính**: Trang chủ, Tìm kiếm, Playlist, Yêu thích, Cài đặt.
- **13 chủ đề nhạc TikTok**: TikTok Viral, Trending, Remix, Mashup, Phonk, Chill, Sad, EDM, Nightcore, KPOP, USUK, Anime, Lofi — mỗi chủ đề có màu sắc và chuỗi tìm kiếm riêng.
- **Tìm kiếm** với debounce, gợi ý phổ biến và lịch sử tìm kiếm cục bộ.
- **Phân trang (infinite scroll)** + **pull to refresh**.
- **Phát video nhúng** qua YouTube embed (không cần SDK YouTube).
- **Playlist cục bộ** (SwiftData): tạo, đổi tên, xoá, kéo thả sắp xếp, tìm trong playlist, thêm video từ màn hình chi tiết.
- **Yêu thích cục bộ** (SwiftData): thêm/xoá, tìm kiếm, sắp xếp theo tên hoặc thời gian.
- **Hero animation** khi mở chi tiết video (iOS 18 `.zoom`, fallback mượt trên iOS 17).
- **Cache ảnh 3 tầng** (RAM → đĩa → mạng) để tiết kiệm quota & dữ liệu.
- **Giao diện** hỗ trợ Dark/Light/System, skeleton loading, empty/error state.
- **API Key** an toàn: build-time qua `.xcconfig`, runtime qua Keychain — không hardcode trong mã nguồn.

## Yêu cầu

- **Xcode 16+** (dùng `PBXFileSystemSynchronizedRootGroup`, iOS 18 API trong code).
- **iOS 17.0+** (deployment target).
- **macOS** có Xcode và (khuyến nghị) Git.

## Bắt đầu nhanh

```bash
# 1. Mở project
open TikMusic.xcodeproj

# 2. (Bắt buộc) Cấu hình API Key
#    Sửa file Config/Config.xcconfig, thay:
YOUTUBE_API_KEY = YOUR_YOUTUBE_API_KEY
#    bằng key thật của bạn (tạo tại console.cloud.google.com/apis/credentials)

# 3. Chọn thiết bị/simulator rồi Cmd+R để chạy.
#    Chạy unit test: Cmd+U
```

Hoặc không cần sửa file — nhập API Key trực tiếp trong **Cài đặt → Quản lý API Key** sau khi chạy app.

## Cấu trúc thư mục

```
.
├── Config/
│   └── Config.xcconfig            # Build settings chung (chứa YOUTUBE_API_KEY)
├── TikMusic.xcodeproj/            # Dự án Xcode (đã cấu hình sẵn 2 targets)
├── TikMusic/
│   ├── App/                       # Entry point, RootView
│   ├── Support/Info.plist         # Đọc $(YOUTUBE_API_KEY)
│   ├── Resources/Assets.xcassets  # AppIcon, AccentColor
│   ├── Core/
│   │   ├── Networking/            # APIClient, RequestBuilder, retry, error...
│   │   ├── Cache/                 # MemoryCache, DiskCache, ImageCache
│   │   ├── Utility/               # AppLogger
│   │   └── DI/                    # DependencyContainer (Composition Root)
│   ├── Domain/
│   │   ├── Entities/              # MusicCategory, MusicVideo, Playlist
│   │   ├── Repository/            # Các protocol repository
│   │   └── UseCases/              # FetchVideos, SearchVideos, Playlist, Favorites
│   ├── Data/
│   │   ├── Models/                # YouTube DTO + Mapper (decode/parse)
│   │   ├── Repositories/          # YouTubeVideoRepository, SwiftData repos, API Key
│   │   └── Local/                 # SwiftDataModels, SearchHistoryStore
│   └── Presentation/
│       ├── Theme/                 # AppTheme, ColorSchemeManager
│       ├── ViewModels/            # MVVM ViewModels (@Observable)
│       ├── Components/            # CachedAsyncImage, Shimmer, StateViews...
│       ├── Views/                 # Home, Search, Detail, Playlist, Favorites, Settings
│       └── PreviewContent/        # Dữ liệu mẫu cho Xcode Preview
└── TikMusicTests/                 # Unit tests (12 file, ~60 tests)
```

## Tài liệu khác

- [INSTALL.md](INSTALL.md) — hướng dẫn cài đặt & cấu hình chi tiết.
- [ARCHITECTURE.md](ARCHITECTURE.md) — kiến trúc, luồng dữ liệu, quy ước.
- [TESTING.md](TESTING.md) — cách chạy và viết unit test.
- [CHANGELOG.md](CHANGELOG.md) — lịch sử thay đổi.
- [TODO.md](TODO.md) — các ý tưởng cải tiến tiếp theo.
- [PROGRESS.md](PROGRESS.md) — nhật ký tiến độ dự án.

## Lưu ý pháp lý

- Ứng dụng không liên kết với TikTok hoặc YouTube.
- Nội dung video thuộc về các kênh sở hữu trên YouTube.
- Việc sử dụng YouTube Data API phải tuân thủ [Điều khoản dịch vụ của Google](https://developers.google.com/youtube/terms/api-services-terms-of-service).

## Giấy phép

Xem [LICENSE](LICENSE).
