# TODO / Cải tiến tiếp theo

Danh sách các ý tưởng, tác vụ còn lại và cải tiến cho **TikMusic**.

## Ưu tiên cao (để hoàn thiện v1)

- [ ] **Build lần đầu trên Xcode** (macOS) — sửa lỗi compile/lint nếu có.
- [ ] Chạy toàn bộ unit test (`Cmd+U`) và sửa test fail.
- [ ] Kiểm tra luồng thêm API Key (build-time + runtime) trên máy thật.
- [ ] Kiểm tra hero animation trên iOS 17 (fallback path).

## Giao diện & UX

- [ ] Thay app icon bằng thiết kế chuyên nghiệp hơn (hiện là gradient + nốt nhạc đơn giản).
- [ ] Thêm dark-mode riêng cho thumbnail placeholder / skeleton.
- [ ] Hiển thị thumbnail lớn hơn trên iPad (adapt `TARGETED_DEVICE_FAMILY = 1,2` nếu cần).
- [ ] Haptics khi yêu thích / thêm playlist.
- [ ] Toàn màn hình khi phát video (landscape) — hiện chỉ inline.

## Tính năng

- [ ] Lưu lịch sử phát / tiếp tục xem (SwiftData).
- [ ] Chế độ "phát nền" (audio) — cần xử lý chính sách phức tạp của YouTube.
- [ ] Lọc video theo kênh, thêm nhiều chủ đề hơn (V-Pop, Dance, Workout...).
- [ ] Tải danh sách kênh / avatar kênh hiển thị trên chi tiết video.
- [ ] Export/import playlist (JSON).
- [ ] Hỗ trợ nhiều ngôn ngữ (Localizable).
- [ ] Widget / Shortcut mở nhanh chủ đề.

## Kỹ thuật

- [ ] Bật `SWIFT_STRICT_CONCURRENCY = complete` và xử lý các cảnh báo Sendable.
- [ ] Thêm UI tests (XCUITest) cho luồng chính: Home → Chi tiết → Yêu thích.
- [ ] Tách `YouTubeVideoRepository` bổ sung cache dữ liệu (tránh gọi lại API khi quay lại).
- [ ] Thêm màn hình onboarding giải thích cách cấu hình API Key.
- [ ] Analytics tối giản (tuỳ chọn, trong lúc không vi phạm quyền riêng tư).
- [ ] GitHub Actions: lint + build thử bằng `xcodebuild` (khi repo lên macOS runner).

## Bảo mật & Vận hành

- [ ] Quyết định có commit `Config/Config.xcconfig` hay không (đang bị gitignore).
- [ ] Cân nhắc `keychain-access-groups` nếu hỗ trợ nhiều app/team.
- [ ] Kiểm tra giới hạn quota và hiển thị trạng thái hạn mức cho người dùng.
