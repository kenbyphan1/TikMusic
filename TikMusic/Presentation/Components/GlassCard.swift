import SwiftUI

/// Thẻ kính (glass card) — nền mờ theo hiệu ứng `ultraThinMaterial`.
///
/// Được dùng cho search bar, chip, sheet... tạo cảm giác hiện đại
/// giống phong cách Apple Music trên iOS.
struct GlassCard<Content: View>: View {

    /// Nội dung bên trong thẻ.
    private let content: Content

    /// Độ bo góc.
    var cornerRadius: CGFloat = AppTheme.cardCornerRadius

    /// Khởi tạo thẻ kính.
    init(cornerRadius: CGFloat = AppTheme.cardCornerRadius, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
            )
    }
}

#Preview {
    GlassCard {
        HStack {
            Image(systemName: "magnifyingglass")
            Text("Tìm kiếm bài hát...")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    .padding()
    .background(Color(.systemBackground))
}
