import SwiftUI

/// Thẻ hiển thị một video trong lưới danh sách.
///
/// Gồm: thumbnail, tiêu đề, tên kênh, lượt xem và badge thời lượng.
struct VideoCardView: View {

    /// Video cần hiển thị.
    let video: MusicVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vùng thumbnail.
            ZStack {
                CachedAsyncImage(url: video.thumbnailURL)
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Badge thời lượng (góc dưới phải).
                if let duration = video.duration {
                    Text(DurationFormatter.format(duration))
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(6)
                }
            }

            // Tiêu đề.
            Text(video.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Kênh + lượt xem.
            VStack(alignment: .leading, spacing: 2) {
                Text(video.channelTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let viewCount = video.viewCount {
                    Text("\(CompactNumberFormatter.compact(viewCount)) lượt xem")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    VideoCardView(
        video: MusicVideo(
            id: "abc123",
            title: "Đây là một bài hát rất hay để test hiển thị tiêu đề dài trên nhiều dòng",
            channelTitle: "Music Channel",
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/abc123/hqdefault.jpg"),
            viewCount: 1_234_567,
            duration: 253
        )
    )
    .frame(width: 180)
    .padding()
}
