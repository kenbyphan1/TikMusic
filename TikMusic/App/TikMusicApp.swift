import SwiftUI

/// Entry point của ứng dụng TikMusic.
///
/// Khởi tạo `DependencyContainer` — toàn bộ đồ thị phụ thuộc (DI).
@main
struct TikMusicApp: App {

    /// Container phụ thuộc dùng chung toàn app.
    @State private var container: DependencyContainer

    init() {
        _container = State(initialValue: DependencyContainer())
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
