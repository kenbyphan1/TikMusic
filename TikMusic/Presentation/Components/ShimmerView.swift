import SwiftUI

/// Hiệu ứng shimmer (ánh sáng di chuyển) dùng cho skeleton loading.
///
/// Lớp gradient trong suốt chạy ngang qua nội dung theo vòng lặp,
/// tạo cảm giác dữ liệu "đang tải".
struct ShimmerModifier: ViewModifier {

    /// Vị trí ánh sáng hiện tại (0 → 1).
    @State private var progress: CGFloat = 0

    /// Độ rộng vùng ánh sáng so với chiều rộng nội dung.
    private let highlightWidth: CGFloat = 0.45

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let offset = -width + (width + width * highlightWidth * 2) * progress

                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.55),
                            .clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: width * highlightWidth)
                    .rotationEffect(.degrees(18))
                    .offset(x: offset)
                    .onAppear {
                        // Vòng lặp vô hạn: chạy hết rồi quay về đầu.
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            progress = 1
                        }
                    }
                }
                .allowsHitTesting(false)
            )
            .clipped()
    }
}

/// Khối skeleton (placeholder xám) khi dữ liệu đang tải.
struct SkeletonView: View {
    /// Độ bo góc.
    var cornerRadius: CGFloat = 12

    /// Chiều cao cố định (nil = theo nội dung).
    var height: CGFloat? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(height: height)
            .modifier(ShimmerModifier())
    }
}

/// Khối skeleton hình ảnh tỷ lệ 16:9.
struct SkeletonImageBlock: View {
    var body: some View {
        Color(.systemGray5)
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .modifier(ShimmerModifier())
    }
}

/// Extension tiện dùng cho View.
extension View {
    /// Áp dụng hiệu ứng shimmer cho view.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    VStack(spacing: 16) {
        SkeletonView(height: 16)
        SkeletonView(height: 16, cornerRadius: 8)
        SkeletonImageBlock()
    }
    .padding()
}
