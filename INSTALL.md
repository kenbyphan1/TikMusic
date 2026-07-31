# Cài đặt & Cấu hình TikMusic

Hướng dẫn từng bước để build và chạy TikMusic trên **macOS với Xcode 16+**.

---

## 1. Chuẩn bị

- **macOS** mới nhất (Sonoma/Sequoia hoặc mới hơn).
- **Xcode 16+** (tải từ App Store hoặc [developer.apple.com](https://developer.apple.com/download/)).

> Dự án được tạo trên Windows nên **chưa từng được build**. Lần mở bằng Xcode đầu tiên
> Xcode sẽ tự nhận diện các thư mục theo `PBXFileSystemSynchronizedRootGroup` — không cần
> thêm file thủ công vào target.

## 2. Mở project

```bash
open TikMusic.xcodeproj
```

Hoặc: mở Finder, nhấp chuột phải vào `TikMusic.xcodeproj` → **Open with Xcode**.

Nếu Xcode hỏi nhập passphrase cho module hoặc hiện cảnh báo "project format", chọn **Convert/Use** — 
dự án dùng format mới (objectVersion 77) của Xcode 16.

## 3. (Bắt buộc) Cấu hình YouTube Data API Key

Ứng dụng cần một **YouTube Data API Key** mới hoạt động:

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/) → tạo dự án mới (hoặc dùng dự án có sẵn).
2. Bật API **YouTube Data API v3**:
   - **APIs & Services → Library → tìm "YouTube Data API v3" → Enable**.
3. Tạo key:
   - **APIs & Services → Credentials → Create Credentials → API key**.
   - Nên **Restrict key** (chỉ cho YouTube Data API v3, giới hạn theo IP/bundle id của app) để an toàn.
4. Đưa key vào project theo **một trong hai cách**:

### Cách A — Build-time key (khuyến nghị cho developer)

Sửa file `Config/Config.xcconfig`:

```xcconfig
YOUTUBE_API_KEY = AIzaSy...   // key của bạn
```

Giá trị này được nhúng vào `Info.plist` qua `$(YOUTUBE_API_KEY)` và app đọc tại runtime.

> Lưu ý: file `Config/Config.xcconfig` đang nằm trong `.gitignore`. Nếu bạn muốn chia sẻ
> key cho team qua git, hãy bỏ dòng `Config/Config.xcconfig` khỏi `.gitignore`.

### Cách B — Runtime key (nhập ngay trong app)

Giữ nguyên placeholder trong `Config.xcconfig`. Sau khi chạy app:
**Cài đặt → Quản lý API Key → nhập key → Lưu.**
Key được lưu trong **Keychain** và được ưu tiên hơn key build-time.

## 4. Build & chạy

- Chọn **scheme TikMusic** (mặc định) và một **simulator iPhone** (iOS 17+).
- Nhấn **Cmd+R** để build & chạy.
- Lần build đầu có thể hơi lâu (index + compile).

### Lỗi thường gặp

| Lỗi | Cách xử lý |
| --- | --- |
| `Build input file not found` | Mở lại project để Xcode đồng bộ thư mục; đảm bảo các thư mục con không bị bỏ trống. |
| `Signing for "TikMusic" requires a development team` | Chọn **TARGETS → TikMusic → Signing & Capabilities → chọn team** (dùng tài khoản Apple miễn phí cũng được). |
| App chạy nhưng báo "Chưa cấu hình API Key" | Kiểm tra lại key trong `Config.xcconfig` **hoặc** nhập key runtime trong Cài đặt. |
| `403 quotaExceeded` | Hết quota YouTube API miễn phí (10.000 units/ngày). Chờ hết ngày hoặc tăng hạn mức. |
| Preview báo lỗi | SwiftUI Preview chạy độc lập; bấm **Resume** lại. Một số preview cần simulator (Keychain). |

## 5. Chạy unit test

- **Cmd+U** để chạy toàn bộ test trong scheme (target `TikMusicTests`).
- Hoặc Product → **Test**.
- Xem chi tiết trong [TESTING.md](TESTING.md).

## 6. Chạy trên thiết bị thật (không bắt buộc)

1. Cắm iPhone, chọn thiết bị trong Xcode.
2. Đảm bảo Signing có team hợp lệ (mục 4).
3. Cấu hình key theo Cách A hoặc B rồi chạy.

---

### Kiểm tra môi trường sau khi hoàn tất

- [ ] Mở được `TikMusic.xcodeproj` bằng Xcode 16+.
- [ ] Build Debug thành công trên simulator.
- [ ] Có YouTube Data API Key hợp lệ (build hoặc runtime).
- [ ] Home tải được video theo chủ đề.
- [ ] `Cmd+U` — các unit test pass.
