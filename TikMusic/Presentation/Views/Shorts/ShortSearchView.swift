import SwiftUI

/// Tìm kiếm trong Short: theo artist/title/tag.
///
/// Hiển thị kết quả lọc từ danh sách Short đã tải (không gọi lại API) —
/// nhanh, không tốn quota; nhấn kết quả sẽ nhảy tới video đó trong feed.
struct ShortSearchView: View {

    /// ViewModel của feed Short.
    @Bindable var viewModel: ShortsViewModel

    /// Từ khoá tìm kiếm.
    @State private var query = ""

    /// Đóng sheet.
    @Environment(\.dismiss) private var dismiss

    /// Kết quả lọc theo từ khoá.
    private var results: [ShortVideo] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return viewModel.shorts.filter { short in
            short.title.localizedCaseInsensitiveContains(trimmed)
                || short.artist.localizedCaseInsensitiveContains(trimmed)
                || short.tags.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Ô tìm kiếm.
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Tìm artist, tiêu đề, tag...", text: $query)
                    .font(AppTheme.bodyFont)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.submitSearch()
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius, style: .continuous))
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, 12)

            if results.isEmpty {
                emptyState
            } else {
                resultsList
            }
        }
        .navigationTitle("Tìm trong Short")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Đóng") {
                    dismiss()
                    viewModel.cancelSearch()
                }
            }
        }
    }

    // MARK: - Results

    private var resultsList: some View {
        List(results) { short in
            Button {
                // Nhảy tới video trong feed.
                if let index = viewModel.shorts.firstIndex(where: { $0.id == short.id }) {
                    viewModel.select(index: index)
                }
                dismiss()
                viewModel.cancelSearch()
            } label: {
                HStack(spacing: 12) {
                    CachedAsyncImage(url: short.thumbnailURL)
                        .frame(width: 56, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(short.title)
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(short.artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !short.tags.isEmpty {
                            Text(short.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.accent)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(query.isEmpty ? "Gõ từ khoá để tìm trong Short" : "Không tìm thấy kết quả")
                .font(AppTheme.bodyFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 40)
    }
}
