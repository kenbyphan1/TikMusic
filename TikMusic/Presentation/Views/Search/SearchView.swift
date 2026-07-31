import SwiftUI

/// Màn hình Tìm kiếm.
///
/// Hiển thị:
/// - Ô tìm kiếm với debounce (chỉ tìm sau khi dừng gõ).
/// - Gợi ý & lịch sử tìm kiếm khi chưa gõ gì.
/// - Kết quả tìm kiếm với infinite scroll.
///
/// Dùng chung cho tab Tìm kiếm và sheet tìm kiếm từ Trang chủ.
struct SearchView: View {

    /// ViewModel của màn hình.
    @Bindable var viewModel: SearchViewModel

    /// Container tiêm phụ thuộc.
    @Environment(DependencyContainer.self) private var container

    /// Namespace cho hero animation.
    @Namespace private var zoomNamespace

    /// Cột của lưới kết quả.
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    /// Có focus ô tìm kiếm không (dùng để focus khi mở).
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    searchField
                    content
                }
                .padding(.horizontal, AppTheme.padding)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Tìm kiếm")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: MusicVideo.self) { video in
                VideoDetailView(viewModel: container.makeVideoDetailViewModel(video: video))
                    .heroZoom(sourceID: video.id, in: zoomNamespace)
            }
        }
        .onAppear {
            // Tự focus khi mở để gõ ngay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSearchFieldFocused = true
            }
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.accent)

            TextField("Tìm kiếm bài hát, ca sĩ...", text: viewModel.queryBinding)
                .font(AppTheme.bodyFont)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFieldFocused)
                .onSubmit {
                    viewModel.searchNow()
                }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.updateQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            Color(.systemGray6),
            in: RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius, style: .continuous)
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            suggestionsSection
        } else {
            resultsContent
        }
    }

    // MARK: - Suggestions & history

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Lịch sử tìm kiếm.
            if !viewModel.history.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Tìm kiếm gần đây")
                            .font(AppTheme.headlineFont)
                        Spacer()
                        Button("Xoá") {
                            viewModel.clearHistory()
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                    }

                    ForEach(viewModel.history, id: \.self) { term in
                        Button {
                            viewModel.selectSuggestion(term)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                Text(term)
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Gợi ý phổ biến.
            VStack(alignment: .leading, spacing: 10) {
                Text("Gợi ý phổ biến")
                    .font(AppTheme.headlineFont)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(SearchViewModel.popularSuggestions, id: \.self) { suggestion in
                            Button {
                                viewModel.selectSuggestion(suggestion)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                    Text(suggestion)
                                        .font(.subheadline.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Color(.systemGray6),
                                    in: Capsule()
                                )
                                .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            skeletonGrid
        case .loaded:
            resultGrid
        case .empty:
            EmptyStateView(
                symbolName: "magnifyingglass",
                title: "Không tìm thấy kết quả",
                message: "Không có video nào khớp với \"\(viewModel.query)\". Thử từ khoá khác nhé."
            )
        case .error(let message):
            if viewModel.isMissingAPIKey {
                missingAPIKeyView
            } else {
                ErrorStateView(message: message) {
                    viewModel.searchNow()
                }
            }
        }
    }

    private var resultGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.results) { video in
                NavigationLink(value: video) {
                    VideoCardView(video: video)
                        .heroSource(id: video.id, in: zoomNamespace)
                }
                .buttonStyle(.plain)
                .onAppear {
                    Task { await viewModel.loadMoreIfNeeded(current: video) }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var skeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonImageBlock()
                    SkeletonView(height: 14)
                    SkeletonView(cornerRadius: 6, height: 12)
                }
            }
        }
    }

    private var missingAPIKeyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(AppTheme.accentGradient)
            Text("Chưa cấu hình API Key")
                .font(AppTheme.titleFont)
            Text("Thêm YouTube Data API Key trong Cài đặt để tìm kiếm.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

#Preview {
    SearchView(viewModel: SearchViewModel(
        searchVideosUseCase: SearchVideosUseCase(
            repository: YouTubeVideoRepository(
                client: APIClient(session: URLSession.shared),
                apiKeyProvider: APIKeyProvider()
            )
        ),
        searchHistoryStore: SearchHistoryStore(),
        apiKeyProvider: APIKeyProvider()
    ))
    .environment(DependencyContainer())
}
