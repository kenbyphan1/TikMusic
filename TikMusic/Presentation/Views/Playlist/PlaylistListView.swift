import SwiftUI
import UIKit

/// Màn hình danh sách playlist.
///
/// Hỗ trợ: tạo, đổi tên (context menu), xoá (swipe), mở chi tiết playlist.
struct PlaylistListView: View {

    /// ViewModel của màn hình.
    @Bindable var viewModel: PlaylistListViewModel

    /// Container tiêm phụ thuộc.
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.playlists.isEmpty {
                    EmptyStateView(
                        symbolName: "music.note.list",
                        title: "Chưa có playlist",
                        message: "Tạo playlist đầu tiên của bạn để lưu các bài hát và xem lại bất cứ lúc nào."
                    )
                } else {
                    List {
                        ForEach(viewModel.playlists) { playlist in
                            NavigationLink(value: playlist) {
                                playlistRow(playlist)
                            }
                            .contextMenu {
                                renameButton(playlist)
                                deleteButton(playlist)
                            }
                        }
                        .onDelete(perform: deletePlaylists)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Playlist")
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(viewModel: container.makePlaylistDetailViewModel(playlist: playlist))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Tạo playlist mới")
                }
            }
            .sheet(isPresented: $viewModel.isShowingCreateSheet) {
                CreatePlaylistView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.load()
        }
    }

    /// Hàng hiển thị một playlist.
    private func playlistRow(_ playlist: Playlist) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.accentGradient)
                Image(systemName: "music.note.list")
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(AppTheme.headlineFont)
                    .lineLimit(1)
                Text("\(playlist.videoCount) bài hát")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    /// Nút đổi tên trong context menu.
    private func renameButton(_ playlist: Playlist) -> some View {
        Button("Đổi tên", systemImage: "pencil") {
            presentRenameAlert(for: playlist)
        }
    }

    /// Nút xoá trong context menu.
    private func deleteButton(_ playlist: Playlist) -> some View {
        Button("Xoá", systemImage: "trash", role: .destructive) {
            viewModel.delete(playlist)
        }
    }

    /// Xoá nhiều playlist theo index set (swipe to delete).
    private func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            guard viewModel.playlists.indices.contains(index) else { continue }
            viewModel.delete(viewModel.playlists[index])
        }
    }

    /// Hiện alert nhập tên mới cho playlist.
    private func presentRenameAlert(for playlist: Playlist) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?.keyWindow,
            let root = scene.rootViewController else { return }

        let alert = UIAlertController(
            title: "Đổi tên playlist",
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.text = playlist.name
            textField.placeholder = "Tên playlist"
        }
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { _ in
            let newName = alert.textFields?.first?.text ?? ""
            viewModel.rename(playlist, to: newName)
        })

        root.present(alert, animated: true)
    }
}

#Preview {
    PlaylistListView(viewModel: PlaylistListViewModel(
        playlistUseCase: PlaylistUseCase(
            repository: SwiftDataPlaylistRepository(context: PreviewData.container.mainContext)
        )
    ))
    .environment(DependencyContainer(modelContainer: PreviewData.container))
}
