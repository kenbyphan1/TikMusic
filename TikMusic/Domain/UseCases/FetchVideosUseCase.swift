import Foundation

/// UseCase lấy danh sách video theo chủ đề.
///
/// UseCase đóng gói một quy trình nghiệp vụ duy nhất, che giấu chi tiết
/// triển khai của repository cho tầng Presentation.
struct FetchVideosUseCase {
    private let repository: VideoRepositoryProtocol

    init(repository: VideoRepositoryProtocol) {
        self.repository = repository
    }

    /// Lấy video theo chủ đề.
    func execute(category: MusicCategory, pageToken: String?) async throws -> VideoPage {
        try await repository.fetchVideos(category: category, pageToken: pageToken)
    }
}
