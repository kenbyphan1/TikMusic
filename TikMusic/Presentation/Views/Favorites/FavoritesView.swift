import SwiftUI

/// Màn hình Danh sách yêu thích.
///
/// Hỗ trợ: thêm/xoá, tìm kiếm, sắp xếp theo tên hoặc thời gian.
struct FavoritesView: View {

    /// ViewModel của màn hình.
    @Bindable var viewModel: FavoritesViewModel

    /// Container tiêm phụ thuộc.
    @Environment(DependencyContainer.self) private var container

    /// Namespace cho hero animation.
    @Namespace private var zoomNamespace

    /// Cột của lưới video.
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    EmptyStateView(
                        symbolName: "heart",
                        title: "Chưa có yêu thích",
                        message: "Nhấn biểu tượng trái tim trên màn hình chi tiết video để lưu vào đây."
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Yêu thích")
            .navigationDestination(for: MusicVideo.self) { video in
                VideoDetailView(viewModel: container.makeVideoDetailViewModel(video: video))
                    .heroZoom(sourceID: video.id, in: zoomNamespace)
            }
            .toolbar {
                if !viewModel.favorites.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Xoá tất cả", systemImage: "trash", role: .destructive) {
                                viewModel.removeAll()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                searchField
                sortMenu
                videoGrid
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.accent)

            TextField("Tìm trong yêu thích...", text: $viewModel.searchText)
                .font(AppTheme.bodyFont)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            Color(.systemGray6),
            in: RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius, style: .continuous)
        )
    }

    // MARK: - Sort

    private var sortMenu: some View {
        HStack {
            Text("\(viewModel.filteredFavorites.count) bài hát")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Menu {
                Picker("Sắp xếp", selection: $viewModel.sortOption) {
                    ForEach(FavoritesViewModel.SortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(viewModel.sortOption.title)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Color(.systemGray6),
                    in: Capsule()
                )
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Grid

    private var videoGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.filteredFavorites) { video in
                NavigationLink(value: video) {
                    VideoCardView(video: video)
                        .heroSource(id: video.id, in: zoomNamespace)
                        .overlay(alignment: .topTrailing) {
                            // Nút xoá nhanh.
                            Button {
                                viewModel.remove(video)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(.black.opacity(0.55), in: Circle())
                            }
                            .padding(6)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    FavoritesView(viewModel: FavoritesViewModel(
        favoritesUseCase: FavoritesUseCase(
            repository: SwiftDataFavoritesRepository(context: PreviewData.container.mainContext)
        )
    ))
    .environment(DependencyContainer(modelContainer: PreviewData.container))
}
