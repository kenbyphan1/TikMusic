import Foundation

/// UseCase tìm video thay thế khi video gốc không thể phát trong app
/// (bị chủ kênh cấm nhúng → lỗi 101/150).
///
/// Chiến lược:
/// 1. Kiểm tra cache — nếu đã từng tìm được video phát được cho bài này
///    thì dùng ngay, không tốn API.
/// 2. Tìm kiếm YouTube theo tên bài hát (tự bỏ các hậu tố phổ biến như
///    "(Official Video)", "[Lyrics]"...) kèm tên ca sĩ/kênh.
/// 3. Lọc ra những video embeddable được (gọi `part=status`).
/// 4. Ưu tiên video có thời lượng gần nhất với video gốc (khớp bản nhạc).
/// 5. Ghi cache để lần sau mở nhanh hơn.
struct VideoFallbackUseCase {

    private let repository: VideoRepositoryProtocol
    private let cacheStore: PlaybackCacheStore

    init(repository: VideoRepositoryProtocol, cacheStore: PlaybackCacheStore) {
        self.repository = repository
        self.cacheStore = cacheStore
    }

    /// Tìm video thay thế cho video gốc.
    ///
    /// - Parameter video: video gốc không phát được.
    /// - Returns: video thay thế đã xác minh embeddable, hoặc `nil` nếu
    ///   không tìm được video nào phù hợp.
    func findAlternative(for video: MusicVideo) async throws -> MusicVideo? {
        // Ưu tiên cache.
        if let cached = cacheStore.alternative(for: video.id) {
            AppLogger.info("Fallback: dùng cache cho \(video.id)")
            return cached
        }

        let query = Self.buildSearchQuery(for: video)
        guard !query.isEmpty else { return nil }

        let page = try await repository.searchVideos(query: query, pageToken: nil)
        var candidates = page.videos.filter { $0.id != video.id }
        guard !candidates.isEmpty else { return nil }

        // Chỉ giữ video embeddable được.
        let embeddableIDs = Set(try await repository.filterEmbeddable(ids: candidates.map(\.id)))
        candidates = candidates.filter { embeddableIDs.contains($0.id) }
        guard !candidates.isEmpty else { return nil }

        // Ưu tiên thời lượng gần với video gốc (tránh nhầm bản remix/mashup).
        let best = candidates.min { lhs, rhs in
            distance(lhs.duration, to: video.duration) < distance(rhs.duration, to: video.duration)
        } ?? candidates[0]

        cacheStore.save(alternative: best, for: video.id)
        AppLogger.info("Fallback: tìm được \(best.id) cho \(video.id)")
        return best
    }

    // MARK: - Private

    /// Khoảng cách giữa hai thời lượng (nil được coi là cách xa vô cùng).
    private func distance(_ a: TimeInterval?, to b: TimeInterval?) -> TimeInterval {
        guard let a, let b else { return .greatestFiniteMagnitude }
        return abs(a - b)
    }

    /// Dựng query tìm kiếm từ tiêu đề + ca sĩ, bỏ hậu tố phổ biến.
    static func buildSearchQuery(for video: MusicVideo) -> String {
        var title = video.title

        // Bỏ các cụm trong ngoặc vuông/tròn: [Official Video], (Lyrics), (Cover)...
        title = title.replacingOccurrences(
            of: #"([\[\(])(.*?)([\]\)])"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // Bỏ các từ khóa đặc trưng đứng cuối: "Official", "Official Audio", "Lyrics"...
        title = title.replacingOccurrences(
            of: #"(?i)\b(official (audio|video|lyrics|music)|audio|lyrics|visualizer|official)\b.*$"#,
            with: ""
        )
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)

        var parts = [title]
        if !video.channelTitle.isEmpty {
            parts.append(video.channelTitle)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
