import Foundation

/// Bộ chuyển đổi giữa DTO (Data layer) và `MusicVideo` (Domain layer).
///
/// Tập trung toàn bộ logic map/parse để dễ kiểm thử và tránh lặp code.
enum MusicVideoMapper {

    /// Chuyển một phần tử kết quả search thành `MusicVideo`.
    ///
    /// - Parameters:
    ///   - item: DTO kết quả tìm kiếm.
    ///   - category: chủ đề video (nếu có).
    /// - Returns: `MusicVideo` hoặc `nil` nếu thiếu videoId.
    static func video(from item: YouTubeSearchItemDTO, category: MusicCategory? = nil) -> MusicVideo? {
        guard let videoID = item.id?.videoId, !videoID.isEmpty else {
            return nil
        }
        return video(id: videoID, snippet: item.snippet, category: category)
    }

    /// Chuyển một `YouTubeVideoItemDTO` (đầy đủ thống kê) thành `MusicVideo`.
    static func video(from item: YouTubeVideoItemDTO) -> MusicVideo? {
        guard let videoID = item.id, !videoID.isEmpty else {
            return nil
        }
        let base = video(id: videoID, snippet: item.snippet, category: nil)
        return MusicVideo(
            id: base.id,
            title: base.title,
            channelID: base.channelID,
            channelTitle: base.channelTitle,
            publishedAt: base.publishedAt,
            description: base.description,
            thumbnailURL: base.thumbnailURL,
            thumbnailHighURL: base.thumbnailHighURL,
            viewCount: item.statistics?.viewCount.flatMap(Int.init),
            likeCount: item.statistics?.likeCount.flatMap(Int.init),
            duration: Self.parseDuration(item.contentDetails?.duration),
            category: base.category
        )
    }

    /// Trộn thống kê (lượt xem, lượt thích) vào một video có sẵn.
    static func mergingStatistics(from item: YouTubeVideoItemDTO, into video: MusicVideo) -> MusicVideo {
        MusicVideo(
            id: video.id,
            title: video.title,
            channelID: video.channelID,
            channelTitle: video.channelTitle,
            publishedAt: video.publishedAt,
            description: video.description,
            thumbnailURL: video.thumbnailURL,
            thumbnailHighURL: video.thumbnailHighURL,
            viewCount: item.statistics?.viewCount.flatMap(Int.init) ?? video.viewCount,
            likeCount: item.statistics?.likeCount.flatMap(Int.init) ?? video.likeCount,
            duration: Self.parseDuration(item.contentDetails?.duration) ?? video.duration,
            category: video.category
        )
    }

    /// Dựng `MusicVideo` từ id + snippet (chưa có thống kê).
    private static func video(id: String, snippet: YouTubeSnippetDTO?, category: MusicCategory?) -> MusicVideo {
        let thumbnails = snippet?.thumbnails
        return MusicVideo(
            id: id,
            title: snippet?.title ?? "Không có tiêu đề",
            channelID: snippet?.channelId ?? "",
            channelTitle: snippet?.channelTitle ?? "Unknown",
            publishedAt: Self.parseDate(snippet?.publishedAt),
            description: snippet?.description ?? "",
            thumbnailURL: Self.url(from: thumbnails?.medium?.url ?? thumbnails?.high?.url ?? thumbnails?.default?.url),
            thumbnailHighURL: Self.url(from: thumbnails?.maxres?.url ?? thumbnails?.standard?.url ?? thumbnails?.high?.url),
            category: category
        )
    }

    /// Parse thời lượng ISO 8601 ("PT4M13S") thành giây.
    static func parseDuration(_ isoDuration: String?) -> TimeInterval? {
        guard let isoDuration, !isoDuration.isEmpty else { return nil }
        return ISO8601DurationParser.parse(isoDuration)
    }

    /// Parse ngày tháng theo chuẩn RFC 3339 mà YouTube trả về.
    ///
    /// Hỗ trợ cả trường hợp có phần giây phân số.
    static func parseDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }

        // Thử lại với phần giây phân số.
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }

    /// Dựng URL từ chuỗi, bỏ qua chuỗi rỗng.
    private static func url(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }
}

/// Parser thời lượng ISO 8601 dạng `PnDTnHnMnS` (hoặc `PnW`) về giây.
enum ISO8601DurationParser {

    /// Parse chuỗi ISO 8601 duration thành số giây.
    ///
    /// Ví dụ: `PT4M13S` → 253, `PT1H2M` → 3720, `P1DT2H` → 93600.
    static func parse(_ value: String) -> TimeInterval? {
        var input = value.uppercased()
        guard input.hasPrefix("P") else { return nil }
        input.removeFirst()

        // Tách phần ngày (trước T) và phần thời gian (sau T).
        let datePart: String
        let timePart: String
        if let tIndex = input.firstIndex(of: "T") {
            datePart = String(input[input.startIndex..<tIndex])
            timePart = String(input[input.index(after: tIndex)...])
        } else {
            datePart = input
            timePart = ""
        }

        // Units: ký tự → hệ số giây.
        let dateUnits: [Character: TimeInterval] = ["W": 7 * 86400, "D": 86400]
        let timeUnits: [Character: TimeInterval] = ["H": 3600, "M": 60, "S": 1]

        // Parse phần ngày (có thể rỗng — hợp lệ).
        let (days, okDate) = parseGrouped(datePart, units: dateUnits)
        guard okDate else { return nil }

        // Parse phần thời gian (bắt buộc ít nhất một đơn vị nếu có ký tự T).
        let (time, okTime) = parseGrouped(timePart, units: timeUnits)
        guard okTime else { return nil }

        let total = days + time
        return total > 0 ? total : nil
    }

    /// Quét chuỗi dạng "số+đơn vị số+đơn vị..." và tính tổng giây.
    private static func parseGrouped(_ value: String, units: [Character: TimeInterval]) -> (Double, Bool) {
        guard !value.isEmpty else { return (0, true) }

        let characters = Array(value)
        var index = 0
        var total: Double = 0

        while index < characters.count {
            // Đọc chuỗi số (có thể gồm dấu chấm thập phân).
            var numberString = ""
            while index < characters.count,
                  characters[index].isNumber || characters[index] == "." {
                numberString.append(characters[index])
                index += 1
            }

            // Phải kết thúc bằng một ký tự đơn vị hợp lệ.
            guard index < characters.count,
                  let multiplier = units[characters[index]],
                  let number = Double(numberString) else {
                return (0, false)
            }

            total += number * multiplier
            index += 1
        }

        return (total, true)
    }
}
