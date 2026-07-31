import SwiftUI

/// Sheet tạo playlist mới.
struct CreatePlaylistView: View {

    /// ViewModel danh sách playlist (dùng chung với màn hình chính).
    @Bindable var viewModel: PlaylistListViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên playlist") {
                    TextField("Nhập tên playlist", text: $viewModel.newPlaylistName)
                        .font(AppTheme.bodyFont)
                }
            }
            .navigationTitle("Playlist mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") {
                        viewModel.newPlaylistName = ""
                        viewModel.isShowingCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tạo") {
                        viewModel.createPlaylist()
                    }
                    .disabled(
                        viewModel.newPlaylistName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CreatePlaylistView(viewModel: PlaylistListViewModel(
        playlistUseCase: PlaylistUseCase(
            repository: PreviewData.previewPlaylistRepository
        )
    ))
    .environment(DependencyContainer())
}
