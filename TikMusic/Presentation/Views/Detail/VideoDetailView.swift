import SwiftUI
import UIKit

/// Màn hình Chi tiết video.
///
/// Hiển thị: thumbnail lớn (bấm để phát), tiêu đề, tên kênh, ngày đăng,
/// mô tả, và các nút: Yêu thích, Thêm playlist, Chia sẻ, Mở YouTube.
struct VideoDetailView: View {

    /// ViewModel của màn hình.
    @Bindable var viewModel: VideoDetailViewModel

    /// Có hiển thị sheet chọn playlist không.
    @State private var isShowingPlaylistPicker = false

    /// Có hiển thị trình phát không.
    @State private var isShowingPlayer = false

    /// Tên playlist mới tạo từ sheet.
    @State private var newPlaylistName = ""

    /// Video hiển thị (chi tiết nếu đã tải xong).
    private var video: MusicVideo { viewModel.displayVideo }

    init(viewModel: VideoDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                playerSection
                actionRow
                infoSection
                if !video.description.isEmpty {
                    descriptionSection
                }
            }
            .padding(AppTheme.padding)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $isShowingPlaylistPicker) {
            playlistPicker
        }
        .alert(
            "Thông báo",
            isPresented: Binding(
                get: { viewModel.playlistMessage != nil },
                set: { if !$0 { viewModel.clearPlaylistMessage() } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.clearPlaylistMessage()
            }
        } message: {
            Text(viewModel.playlistMessage ?? "")
        }
    }

    // MARK: - Player / thumbnail

    private var playerSection: some View {
        ZStack {
            if isShowingPlayer {
                YouTubePlayerView(videoID: video.id, autoPlay: true)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                CachedAsyncImage(
                    url: video.thumbnailHighURL ?? video.thumbnailURL
                )
                .aspectRatio(16 / 9, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    // Nút phát ở giữa.
                    Image(systemName: "play.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                        .background(.black.opacity(0.35), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.3), radius: 12)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isShowingPlayer = true
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 0) {
            actionButton(
                symbol: viewModel.isFavorite ? "heart.fill" : "heart",
                title: viewModel.isFavorite ? "Đã thích" : "Yêu thích",
                tint: viewModel.isFavorite ? .red : .primary
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.toggleFavorite()
                }
            }

            actionButton(symbol: "plus.circle", title: "Playlist") {
                isShowingPlaylistPicker = true
            }

            ShareLink(item: video.shareURL) {
                shareLabel
            }
            .frame(maxWidth: .infinity)

            actionButton(symbol: "play.rectangle.fill", title: "YouTube") {
                openYouTube()
            }
        }
        .padding(.vertical, 6)
    }

    /// Nút hành động dạng icon + nhãn.
    private func actionButton(
        symbol: String,
        title: String,
        tint: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    /// Nhãn nút chia sẻ (dùng cho ShareLink).
    private var shareLabel: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 22, weight: .medium))
            Text("Chia sẻ")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(video.title)
                .font(AppTheme.titleFont)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                // Avatar kênh.
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGradient)
                        .frame(width: 34, height: 34)
                    Text(String(video.channelTitle.prefix(1)).uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(video.channelTitle)
                        .font(AppTheme.headlineFont)
                    Text(relativeDateText(video.publishedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Thống kê.
            HStack(spacing: 14) {
                if let viewCount = video.viewCount {
                    statItem(symbol: "eye.fill", text: "\(CompactNumberFormatter.compact(viewCount)) lượt xem")
                }
                if let likeCount = video.likeCount {
                    statItem(symbol: "hand.thumbsup.fill", text: "\(CompactNumberFormatter.compact(likeCount)) thích")
                }
                if let duration = video.duration {
                    statItem(symbol: "clock.fill", text: DurationFormatter.format(duration))
                }
            }
            .padding(.top, 2)
        }
    }

    private func statItem(symbol: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6), in: Capsule())
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mô tả")
                .font(AppTheme.headlineFont)
            Text(video.description)
                .font(AppTheme.bodyFont)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Playlist picker

    private var playlistPicker: some View {
        NavigationStack {
            List {
                // Tạo playlist mới ngay trong sheet.
                Section("Tạo playlist mới") {
                    HStack {
                        TextField("Tên playlist", text: $newPlaylistName)
                            .font(AppTheme.bodyFont)

                        Button("Tạo") {
                            createNewPlaylist()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            AppTheme.accentGradient,
                            in: Capsule()
                        )
                        .disabled(trimmedName.isEmpty)
                        .opacity(trimmedName.isEmpty ? 0.5 : 1)
                    }
                }

                Section("Chọn playlist") {
                    if viewModel.playlists.isEmpty {
                        Text("Chưa có playlist nào. Tạo playlist mới ở trên.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(viewModel.playlists) { playlist in
                            Button {
                                viewModel.addToPlaylist(playlist.id)
                                isShowingPlaylistPicker = false
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "music.note.list")
                                        .foregroundStyle(AppTheme.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(playlist.name)
                                            .font(AppTheme.bodyFont)
                                            .foregroundStyle(.primary)
                                        Text("\(playlist.videoCount) bài hát")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Thêm vào playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        isShowingPlaylistPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// Tên playlist mới sau khi trim.
    private var trimmedName: String {
        newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Tạo playlist mới từ ô nhập.
    private func createNewPlaylist() {
        guard !trimmedName.isEmpty else { return }
        viewModel.createPlaylist(name: trimmedName)
        newPlaylistName = ""
    }

    // MARK: - Actions

    /// Mở video trong ứng dụng YouTube (fallback: trình duyệt).
    private func openYouTube() {
        let appURL = URL(string: "youtube://watch?v=\(video.id)")
        if let appURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(video.url)
        }
    }

    /// Định dạng ngày đăng dạng tương đối ("3 ngày trước").
    private func relativeDateText(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        VideoDetailView(viewModel: VideoDetailViewModel(
            video: PreviewData.videos[0],
            videoRepository: YouTubeVideoRepository(
                client: APIClient(session: URLSession.shared),
                apiKeyProvider: APIKeyProvider()
            ),
            favoritesUseCase: FavoritesUseCase(
                repository: PreviewData.previewFavoritesRepository
            ),
            playlistUseCase: PlaylistUseCase(
                repository: PreviewData.previewPlaylistRepository
            )
        ))
    }
    .environment(DependencyContainer())
}
