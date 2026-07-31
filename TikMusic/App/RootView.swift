import SwiftUI

/// Root view của ứng dụng.
///
/// - Bơm `DependencyContainer` vào môi trường SwiftUI.
/// - Áp dụng chủ đề giao diện (Dark/Light/System) đã chọn.
struct RootView: View {

    /// Container tiêm phụ thuộc.
    @Bindable var container: DependencyContainer

    var body: some View {
        MainTabView(container: container)
            .environment(container)
            .preferredColorScheme(container.colorSchemeManager.resolvedScheme)
            .tint(AppTheme.accent)
    }
}

#Preview {
    RootView(container: DependencyContainer(modelContainer: PreviewData.container))
}
