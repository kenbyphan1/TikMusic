import Foundation
import Observation

/// ViewModel cho màn hình Yêu thích.
///
/// Chịu trách nhiệm: hiển thị, tìm kiếm, sắp xếp, xoá video yêu thích.
@Observable
@MainActor
final class FavoritesViewModel {

    /// Tiêu chí sắp xếp danh sách yêu thích.
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "newest"
        case oldest = "oldest"
        case nameAsc = "nameAsc"
        case nameDesc = "nameDesc"

        var id: String { rawValue }

        /// Tên hiển thị.
        var title: String {
            switch self {
            case .newest: return "Mới nhất"
            case .oldest: return "Cũ nhất"
            case .nameAsc: return "Tên A-Z"
            case .nameDesc: return "Tên Z-A"
            }
        }
    }

    // MARK: - State

    /// Toàn bộ video yêu thích (mới nhất trước).
    private(set) var favorites: [MusicVideo] = []

    /// Từ khoá tìm kiếm.
    var searchText = ""

    /// Tiêu chí sắp xếp hiện tại.
    var sortOption: SortOption = .newest

    // MARK: - Dependencies

    private let favoritesUseCase: FavoritesUseCase

    /// Khởi tạo ViewModel.
    init(favoritesUseCase: FavoritesUseCase) {
        self.favoritesUseCase = favoritesUseCase
    }

    // MARK: - Public API

    /// Danh sách yêu thích sau khi lọc + sắp xếp.
    var filteredFavorites: [MusicVideo] {
        var items = favorites

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed)
                    || $0.channelTitle.localizedCaseInsensitiveContains(trimmed)
            }
        }

        switch sortOption {
        case .newest:
            break // đã được sắp mới nhất trước khi fetch
        case .oldest:
            items.reverse()
        case .nameAsc:
            items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .nameDesc:
            items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }

        return items
    }

    /// Tải danh sách yêu thích.
    func load() {
        favorites = (try? favoritesUseCase.fetchAll()) ?? []
    }

    /// Xoá một video khỏi yêu thích.
    func remove(_ video: MusicVideo) {
        do {
            try favoritesUseCase.remove(videoID: video.id)
            load()
        } catch {
            AppLogger.error("Xoá yêu thích thất bại: \(error.localizedDescription)")
        }
    }

    /// Xoá toàn bộ danh sách yêu thích.
    func removeAll() {
        do {
            try favoritesUseCase.removeAll()
            load()
        } catch {
            AppLogger.error("Xoá toàn bộ yêu thích thất bại: \(error.localizedDescription)")
        }
    }
}
