import SwiftUI

/// Thanh cuộn ngang các chủ đề nhạc (chips).
///
/// Chip được chọn sẽ hiển thị gradient đặc trưng của chủ đề kèm animation.
struct CategoryCarouselView: View {

    /// Danh sách chủ đề.
    let categories: [MusicCategory]

    /// Chủ đề đang chọn (binding để cập nhật từ ngoài).
    @Binding var selection: MusicCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    chip(for: category)
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Chip của một chủ đề.
    private func chip(for category: MusicCategory) -> some View {
        let isSelected = category == selection

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selection = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.symbolName)
                    .font(.caption.weight(.bold))
                Text(category.title)
                    .font(.subheadline.weight(isSelected ? .bold : .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(
                    isSelected
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: category.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color(.systemGray6))
                )
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(
                Capsule().stroke(
                    isSelected ? Color.white.opacity(0.35) : Color.clear,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selection: MusicCategory = .tiktokViral

    CategoryCarouselView(categories: MusicCategory.allCases, selection: $selection)
        .padding()
}
