import SwiftData
import SwiftUI

/// Entry point của ứng dụng TikMusic.
///
/// Khởi tạo:
/// 1. `ModelContainer` của SwiftData (playlist, yêu thích).
/// 2. `DependencyContainer` — toàn bộ đồ thị phụ thuộc (DI).
@main
struct TikMusicApp: App {

    /// Container phụ thuộc dùng chung toàn app.
    @State private var container: DependencyContainer

    init() {
        // Đăng ký các model SwiftData.
        let schema = Schema([
            PlaylistRecord.self,
            PlaylistItemRecord.self,
            FavoriteVideoRecord.self,
        ])

        // Cấu hình lưu trữ trên đĩa (không phải in-memory).
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            _container = State(initialValue: DependencyContainer(modelContainer: modelContainer))
        } catch {
            // Không thể khởi tạo storage — dừng ứng dụng với log rõ ràng.
            AppLogger.error("Không thể khởi tạo SwiftData container: \(error)")
            fatalError("Không thể khởi tạo ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
