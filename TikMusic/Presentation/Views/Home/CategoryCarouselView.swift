import SwiftUI

/// Thanh cuộn ngang các chủ đề nhạc (chips).
///
/// Chip được chọn sẽ hiển thị gradient đặc trưng của chủ đề kèm animation.
/// Nếu `shortsAction` được cung cấp, một chip "Short" sẽ được chèn ngay sau
/// chip Trending để mở feed video dọc.
struct CategoryCarouselView: View {

    /// Danh sách chủ đề.
    let categories: [MusicCategory]

    /// Chủ đề đang chọn (binding để cập nhật từ ngoài).
    @Binding var selection: MusicCategory

    /// Hành động mở feed Short (nil = không hiển thị chip Short).
    var shortsAction: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                    chip(for: category)

                    // Chip "Short" ngay sau Trending.
                    if category == .trending, let shortsAction {
                        shortsChip(action: shortsAction)
                    }
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

    /// Chip "Short" — gradient đen/trắng đặc trưng kiểu video dọc.
    private func shortsChip(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.landscape.rotate")
                    .font(.caption.weight(.bold))
                Text("Short")
                    .font(.subheadline.weight(.bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [.black, .gray.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .foregroundStyle(.white)
            .overlay(
                Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selection: MusicCategory = .tiktokViral

    CategoryCarouselView(
        categories: MusicCategory.allCases,
        selection: $selection,
        shortsAction: {}
    )
    .padding()
}
