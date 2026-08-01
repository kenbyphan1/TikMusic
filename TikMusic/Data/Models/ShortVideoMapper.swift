import Foundation

/// Bộ chuyển đổi giữa DTO YouTube (Data layer) và `ShortVideo` (Domain layer).
///
/// Tách riêng logic map để dễ kiểm thử và tránh lặp code. Tái sử dụng các
/// parser có sẵn trong `MusicVideoMapper` (parse ngày, thời lượng ISO 8601).
enum ShortVideoMapper {

    /// Chuyển một phần tử kết quả search thành `ShortVideo`.
    ///
    /// - Parameters:
    ///   - item: DTO kết quả tìm kiếm.
    ///   - source: nguồn dữ liệu (mặc định `.remote`).
    /// - Returns: `ShortVideo` hoặc `nil` nếu thiếu videoId.
    static func short(from item: YouTubeSearchItemDTO, source: ShortSource = .remote) -> ShortVideo? {
        guard let videoID = item.id?.videoId, !videoID.isEmpty else {
            return nil
        }

        let snippet = item.snippet
        let thumbnails = snippet?.thumbnails
        let thumbnail = Self.url(
            from: thumbnails?.medium?.url ?? thumbnails?.high?.url ?? thumbnails?.default?.url
        )

        return ShortVideo(
            id: videoID,
            title: snippet?.title ?? "Không có tiêu đề",
            artist: snippet?.channelTitle ?? "Unknown",
            thumbnailURL: thumbnail,
            videoURL: URL(string: "https://www.youtube.com/watch?v=\(videoID)")!,
            duration: nil,
            likes: nil,
            views: nil,
            comments: nil,
            shareCount: nil,
            createdAt: MusicVideoMapper.parseDate(snippet?.publishedAt),
            tags: Self.tags(from: snippet?.title, description: snippet?.description),
            source: source
        )
    }

    /// Gộp thống kê (lượt xem, thích, bình luận, thời lượng) vào một Short
    /// đã có sẵn — dữ liệu lấy từ endpoint `videos`.
    static func mergingStatistics(from item: YouTubeVideoItemDTO, into short: ShortVideo) -> ShortVideo {
        ShortVideo(
            id: short.id,
            title: short.title,
            artist: short.artist,
            thumbnailURL: short.thumbnailURL,
            videoURL: short.videoURL,
            duration: MusicVideoMapper.parseDuration(item.contentDetails?.duration) ?? short.duration,
            likes: item.statistics?.likeCount.flatMap(Int.init) ?? short.likes,
            views: item.statistics?.viewCount.flatMap(Int.init) ?? short.views,
            comments: item.statistics?.commentCount.flatMap(Int.init) ?? short.comments,
            shareCount: short.shareCount,
            createdAt: short.createdAt,
            tags: short.tags,
            source: short.source
        )
    }

    /// Trích tag từ tiêu đề + mô tả (các từ bắt đầu bằng `#`).
    ///
    /// Nếu không có hashtag nào, trả về mảng rỗng — UI có thể không hiển thị
    /// tag khi không có dữ liệu.
    private static func tags(from title: String?, description: String?) -> [String] {
        var result: [String] = []

        let titleTags = Self.hashtags(in: title ?? "")
        result.append(contentsOf: titleTags)

        if result.count < 5, let description, !description.isEmpty {
            let descTags = Self.hashtags(in: description)
            result.append(contentsOf: descTags)
        }

        return Array(NSOrderedSet(array: result)).compactMap { $0 as? String }.prefix(8).map { $0 }
    }

    /// Tìm các hashtag trong một chuỗi.
    private static func hashtags(in text: String) -> [String] {
        let pattern = #"#([a-zA-Z0-9_À-ỹ]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r])
        }
    }

    /// Dựng URL từ chuỗi, bỏ qua chuỗi rỗng.
    private static func url(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }
}
