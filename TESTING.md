# Hướng dẫn Testing

Cách chạy, tổ chức và viết unit test cho **TikMusic** (target `TikMusicTests`, framework **XCTest**).

---

## 1. Chạy test

- Mở `TikMusic.xcodeproj` bằng Xcode 16+.
- Chọn scheme **TikMusic** → **Cmd+U** (Product → Test).
- Chạy 1 test: mở file test, bấm nút play cạnh tên test.

> Yêu cầu: máy **macOS có Xcode**. Project hiện chưa được build lần nào
> (sinh trên Windows) — hãy chạy test ngay sau lần build thành công đầu tiên.

## 2. Phạm vi test hiện tại

| File | Nội dung |
| --- | --- |
| `APIClientTests` | decode thành công, lỗi HTTP 404 (không retry), retry 5xx, lỗi decode, quotaExceeded, retry lỗi mạng. |
| `RequestBuilderTests` | query items, percent-encode, headers mặc định, path có khoảng trắng. |
| `DTOMappingTests` | map search item / video item, merge thống kê, parse ngày (RFC3339 + fractional), parse thời lượng ISO 8601, định dạng số/thời lượng. |
| `YouTubeRepositoryTests` | fetchVideos gọi search + videos, searchVideos, fetchVideoDetail, thiếu API Key ném lỗi (không gọi mạng). |
| `CacheTests` | MemoryCache (set/get, removeAll, evict theo count limit), DiskCache (write/read, remove, removeAll, expiry, size). |
| `SwiftDataRepositoryTests` | Playlist (create/fetch, rename, delete cascade, add, dedupe, remove, order), Favorites (add/fetch, dedupe, remove, removeAll, thứ tự mới nhất trước). Dùng ModelContainer in-memory. |
| `SearchHistoryStoreTests` | lịch sử: mới nhất trước, chống trùng, bỏ rỗng, giới hạn 10, remove, clear. |
| `UseCaseTests` | Search (trim query, rỗng → trang rỗng), Fetch (category + pageToken), Playlist (create/rename/add/order/delete, tên rỗng → mặc định), Favorites (add/remove, dedupe/removeAll). |
| `MusicCategoryTests` | 13 chủ đề, query không rỗng, id duy nhất, symbol, gradient, title = rawValue. |
| `APIKeyProviderTests` | build key dùng khi chưa có runtime, runtime ưu tiên hơn, reset → fallback build key, placeholder/empty không được xem là hợp lệ. |

## 3. Mẹo & quy ước

- **Không gọi mạng thật**: `APIClient` dùng `NetworkSession` (protocol). Mock với `MockNetworkSession`
  trong `TikMusicTests/TestHelpers.swift` để trả dữ liệu/status theo kịch bản.
- **Không ghi đĩa thật**: `DiskCache` cho `cachesDirectory` tuỳ chọn → trỏ vào thư mục tạm;
  `SwiftData` dùng `ModelConfiguration(isStoredInMemoryOnly: true)`; `SearchHistoryStore` dùng
  `UserDefaults(suiteName:)` riêng và tự dọn trong `addTeardownBlock`.
- **Không vướng Keychain thật**: các test xoá key cũ qua `APIKeyStore().delete()` trước khi chạy.
- Test phải **nhanh & cô lập**: mỗi test tự tạo dữ liệu riêng.
- Tên test theo mẫu `test<Tình huống><Kết quả mong đợi>` (vd `testSearchEmptyQueryReturnsEmptyPage`).
- Use case/repository mocks đặt ngay trong file test cần chúng (`@unchecked Sendable` khi cần).

## 4. Viết test mới — ví dụ tối thiểu

```swift
import XCTest
@testable import TikMusic

final class DurationFormatterTests: XCTestCase {
    func testFormatsSeconds() {
        XCTAssertEqual(DurationFormatter.format(90), "1:30")
        XCTAssertEqual(DurationFormatter.format(3600), "1:00:00")
    }
}
```

- Đặt trong thư mục `TikMusicTests/` — target tự động nhận file (cơ chế synchronized folder).
- Chạy lại **Cmd+U** để xác nhận test pass.

## 5. Lưu ý concurrency

- Test tương tác với SwiftData / `@MainActor` repository nên đánh dấu `@MainActor` trên phương thức test.
- Các ViewModel `@MainActor` — chỉ test logic thuần (parse, mapping, use case) trực tiếp.
