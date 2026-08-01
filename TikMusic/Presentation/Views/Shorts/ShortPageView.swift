import SwiftUI

/// Một trang trong feed Short: trình phát video + lớp phủ thông tin.
///
/// Chỉ video đang hiển thị (`isActive == true`) được phát; video lân cận được
/// preload (giữ tối đa 3 trong RAM) và giải phóng khi cuộn ra xa.
struct ShortPageView: View {

    /// Short của trang này.
    let short: ShortVideo

    /// Trang này có đang hiển thị (cần phát) không.
    let isActive: Bool

    /// Trang kế tiếp — render player trước (preload) nhưng không phát.
    let isPreloading: Bool

    /// Video có gặp lỗi phát (không khả dụng) không.
    let isUnavailable: Bool

    /// Video có nằm trong yêu thích không.
    let isFavorite: Bool

    /// Vị trí bắt đầu phát (tiếp tục xem).
    let startSeconds: Int

    /// Bật/tắt yêu thích.
    let onToggleFavorite: () -> Void

    /// Chạm vào một tag.
    let onTagTap: (String) -> Void

    /// Player gặp lỗi.
    let onPlayerError: (Int) -> Void

    /// Cập nhật vị trí phát.
    let onTimeUpdate: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                if isActive {
                    YouTubePlayerView(
                        videoID: short.id,
                        autoPlay: true,
                        isActive: true,
                        startSeconds: startSeconds,
                        onPlayerError: onPlayerError,
                        onTimeUpdate: onTimeUpdate
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                } else if isPreloading {
                    // Trang kế tiếp: render player trước để preload.
                    YouTubePlayerView(
                        videoID: short.id,
                        autoPlay: false,
                        isActive: false,
                        startSeconds: startSeconds,
                        onPlayerError: onPlayerError,
                        onTimeUpdate: onTimeUpdate
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                } else if let thumbnailURL = short.thumbnailURL {
                    // Trang xa hơn: chỉ hiển thị thumbnail (giải phóng player).
                    CachedAsyncImage(url: thumbnailURL)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .scaleEffect(1.05)
                } else {
                    Rectangle().fill(Color.black)
                }

                // Lớp phủ thông tin + nút hành động.
                overlayContent
            }
            .clipped()
        }
        .overlay {
            if isActive && isUnavailable {
                unavailableBanner
            }
        }
    }

    // MARK: - Overlay

    private var overlayContent: some View {
        ZStack {
            // Gradient làm nổi chữ trắng.
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack {
                Spacer()

                HStack(alignment: .bottom, spacing: 0) {
                    // Thông tin phía dưới trái.
                    infoColumn
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Thanh hành động bên phải.
                    actionRail
                        .padding(.trailing, 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    /// Thông tin: nghệ sĩ, tiêu đề, tag.
    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !short.artist.isEmpty {
                Text(short.artist)
                    .font(AppTheme.headlineFont.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(short.title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if !short.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(short.tags.prefix(4), id: \.self) { tag in
                            Button {
                                onTagTap(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.white.opacity(0.18), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.trailing, 12)
    }

    /// Thanh hành động: yêu thích, lượt xem, chia sẻ.
    private var actionRail: some View {
        VStack(spacing: 20) {
            // Yêu thích.
            VStack(spacing: 4) {
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(isFavorite ? Color.red : .white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }
                .buttonStyle(.plain)

                if let likes = short.likes {
                    Text(CompactNumberFormatter.compact(likes))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }

            // Bình luận (số liệu, chưa mở bình luận).
            VStack(spacing: 4) {
                Image(systemName: "bubble.right.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4)
                if let comments = short.comments {
                    Text(CompactNumberFormatter.compact(comments))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }

            // Chia sẻ.
            ShareLink(item: short.shareURL) {
                VStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                    if let shares = short.shareCount {
                        Text(CompactNumberFormatter.compact(shares))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    /// Banner báo video không khả dụng.
    private var unavailableBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.yellow)

            Text("Video hiện không khả dụng")
                .font(AppTheme.headlineFont.weight(.semibold))
                .foregroundStyle(.white)

            Text("Đang chuyển sang video tiếp theo...")
                .font(AppTheme.captionFont)
                .foregroundStyle(.white.opacity(0.7))

            ProgressView()
                .tint(.white)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
