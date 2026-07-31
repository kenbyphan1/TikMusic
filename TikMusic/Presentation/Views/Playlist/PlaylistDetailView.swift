import SwiftUI

/// Màn hình chi tiết một playlist.
///
/// Hỗ trợ: đổi tên (sửa trực tiếp), tìm kiếm trong playlist,
/// kéo thả sắp xếp, xoá video khỏi playlist.
struct PlaylistDetailView: View {

    /// ViewModel của màn hình.
    @Bindable var viewModel: PlaylistDetailViewModel

    /// Container tiêm phụ thuộc.
    @Environment(DependencyContainer.self) private var container

    /// Namespace cho hero animation.
    @Namespace private var zoomNamespace

    /// Có đang bật chế độ sắp xếp (drag & drop) không.
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 0) {
            playlistNameField
            searchField

            if viewModel.allVideos.isEmpty {
                EmptyStateView(
                    symbolName: "music.note.list",
                    title: "Playlist trống",
                    message: "Thêm video từ màn hình chi tiết bằng nút Playlist."
                )
            } else {
                videoList
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.allVideos.isEmpty {
                    Button(isEditing ? "Xong" : "Sắp xếp") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isEditing.toggle()
                        }
                    }
                }
            }
        }
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        .navigationDestination(for: MusicVideo.self) { video in
            VideoDetailView(viewModel: container.makeVideoDetailViewModel(video: video))
                .heroZoom(sourceID: video.id, in: zoomNamespace)
        }
    }

    // MARK: - Tên playlist

    private var playlistNameField: some View {
        TextField("Tên playlist", text: viewModel.playlistNameBinding)
            .font(AppTheme.titleFont)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 10)
    }

    // MARK: - Tìm kiếm trong playlist

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.accent)

            TextField("Tìm trong playlist...", text: $viewModel.searchText)
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
        .padding(.horizontal, AppTheme.padding)
        .padding(.bottom, 8)
    }

    // MARK: - Danh sách video

    private var videoList: some View {
        List {
            ForEach(viewModel.filteredVideos) { video in
                NavigationLink(value: video) {
                    videoRow(video)
                }
            }
            .onDelete(perform: deleteVideos)
            .onMove(perform: viewModel.move)
            .moveDisabled(viewModel.isSearching)
        }
        .listStyle(.plain)
    }

    /// Hàng hiển thị một video trong playlist.
    private func videoRow(_ video: MusicVideo) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: video.thumbnailURL)
                .frame(width: 96, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(video.channelTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    /// Xoá video theo index set (swipe to delete).
    private func deleteVideos(at offsets: IndexSet) {
        let items = viewModel.filteredVideos
        for index in offsets {
            guard items.indices.contains(index) else { continue }
            viewModel.remove(items[index])
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistDetailView(viewModel: PlaylistDetailViewModel(
            playlist: Playlist(
                id: UUID(),
                name: "Nhạc yêu thích",
                createdAt: Date(),
                videos: PreviewData.videos
            ),
            playlistUseCase: PlaylistUseCase(
                repository: PreviewData.previewPlaylistRepository
            )
        ))
    }
    .environment(DependencyContainer())
}
