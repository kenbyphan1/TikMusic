import SwiftUI

/// Lịch sử xem Short: "Tiếp tục xem" + "Xem gần đây".
struct ShortsHistoryView: View {

    /// ViewModel của feed Short.
    @Bindable var viewModel: ShortsViewModel

    /// Các Short đang xem dở (tiếp tục xem).
    let recentEntries: [ShortHistoryStore.Entry]

    /// Các Short đã xem gần đây.
    let continueWatchingEntries: [ShortHistoryStore.Entry]

    /// Đóng sheet.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !continueWatchingEntries.isEmpty {
                    Section("Tiếp tục xem") {
                        ForEach(continueWatchingEntries) { entry in
                            row(for: entry, subtitle: "Đang dở · \(progressText(entry))")
                        }
                    }
                }

                Section("Xem gần đây") {
                    if recentEntries.isEmpty {
                        Text("Chưa xem Short nào.")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(recentEntries) { entry in
                            row(for: entry, subtitle: relativeDateText(entry.playedAt))
                        }
                    }
                }
            }
            .navigationTitle("Lịch sử Short")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
                if !recentEntries.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Xoá") {
                            viewModel.clearHistory()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Row

    private func row(for entry: ShortHistoryStore.Entry, subtitle: String) -> some View {
        Button {
            viewModel.resume(entry: entry)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                CachedAsyncImage(url: entry.short.thumbnailURL)
                    .frame(width: 56, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.short.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(entry.short.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    /// Định dạng vị trí phát dở ("1:23").
    private func progressText(_ entry: ShortHistoryStore.Entry) -> String {
        DurationFormatter.format(entry.lastPlayedSeconds)
    }

    /// Định dạng ngày tương đối ("3 phút trước").
    private func relativeDateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
