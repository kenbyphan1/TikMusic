import Foundation

/// UseCase tìm kiếm video nhạc theo từ khoá.
struct SearchVideosUseCase {
    private let repository: VideoRepositoryProtocol

    init(repository: VideoRepositoryProtocol) {
        self.repository = repository
    }

    /// Tìm kiếm video.
    func execute(query: String, pageToken: String?) async throws -> VideoPage {
        // Bỏ khoảng trắng thừa; nếu rỗng trả về trang rỗng ngay.
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .empty
        }
        return try await repository.searchVideos(query: trimmed, pageToken: pageToken)
    }
}
