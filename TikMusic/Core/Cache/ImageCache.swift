import UIKit

/// Cache ảnh 3 tầng: bộ nhớ → đĩa → mạng.
///
/// - Tầng bộ nhớ (RAM): truy cập tức thì cho các ảnh hay dùng.
/// - Tầng đĩa: tái sử dụng giữa các phiên chạy, có thời gian sống.
/// - Tầng mạng: tải ảnh lần đầu qua URLSession.
///
/// Đồng thời "dedupe" các request tải cùng một URL đang chạy dang dở
/// để tránh gọi mạng lặp lại.
@MainActor
final class ImageCache {

    /// Singleton dùng chung trong toàn app.
    static let shared = ImageCache()

    /// Cache RAM.
    private let memory = MemoryCache<NSURL, UIImage>(countLimit: 150)

    /// Cache đĩa (dữ liệu nén).
    private let disk: DiskCache?

    /// Session dùng để tải ảnh từ mạng.
    private let session: NetworkSession

    /// Map các request đang tải dang dở theo URL.
    private var inFlightTasks: [URL: Task<UIImage?, Never>] = [:]

    /// Thời gian sống của ảnh trên đĩa (7 ngày).
    private let diskTTL: TimeInterval = 7 * 24 * 60 * 60

    /// Khởi tạo cache (chủ yếu dùng trong test để cô lập).
    init(session: NetworkSession = URLSession.shared, diskName: String = "ImageCache") {
        self.session = session
        self.disk = try? DiskCache(name: diskName)
    }

    /// Trả về ảnh cho URL, tải từ mạng nếu chưa có trong cache.
    ///
    /// - Parameter url: URL của ảnh.
    /// - Returns: `UIImage` hoặc `nil` nếu tải thất bại.
    func image(for url: URL) async -> UIImage? {
        // 1. Ưu tiên cache RAM/đĩa.
        if let cached = cachedImage(for: url) {
            return cached
        }

        // 2. Nếu đang tải dở cho URL này, chờ task hiện có.
        if let existing = inFlightTasks[url] {
            return await existing.value
        }

        // 3. Tạo task mới để tải + lưu cache.
        let task = Task<UIImage?, Never> { [weak self] in
            await self?.fetchAndCache(url)
        }
        inFlightTasks[url] = task
        let result = await task.value
        inFlightTasks[url] = nil
        return result
    }

    /// Đọc ảnh đồng bộ từ cache (RAM trước, sau đó đĩa).
    func cachedImage(for url: URL) -> UIImage? {
        if let image = memory.value(forKey: url as NSURL) {
            return image
        }
        guard let data = disk?.data(forKey: url.absoluteString, maxAge: diskTTL),
              let image = UIImage(data: data) else {
            return nil
        }
        storeInMemory(image, for: url)
        return image
    }

    /// Xoá toàn bộ cache (RAM + đĩa).
    func clearAll() {
        memory.removeAll()
        disk?.removeAll()
        inFlightTasks.removeAll()
    }

    /// Tổng dung lượng ảnh đang lưu trên đĩa (bytes).
    var diskSizeBytes: Int {
        disk?.totalSizeBytes ?? 0
    }

    // MARK: - Private

    /// Tải ảnh từ mạng rồi lưu vào cache.
    private func fetchAndCache(_ url: URL) async -> UIImage? {
        do {
            let (data, _) = try await session.data(for: URLRequest(url: url))
            guard let image = UIImage(data: data) else {
                AppLogger.error("ImageCache: dữ liệu không phải ảnh cho \(url)")
                return nil
            }
            store(image, for: url)
            return image
        } catch {
            AppLogger.error("ImageCache: tải ảnh thất bại \(error.localizedDescription)")
            return nil
        }
    }

    /// Lưu ảnh vào cả RAM và đĩa.
    private func store(_ image: UIImage, for url: URL) {
        storeInMemory(image, for: url)
        // Nén xuống còn 80% chất lượng để tiết kiệm dung lượng đĩa.
        let data = image.jpegData(compressionQuality: 0.8) ?? image.pngData()
        disk?.set(data, forKey: url.absoluteString)
    }

    /// Lưu ảnh vào RAM với chi phí ước tính theo kích thước điểm ảnh.
    private func storeInMemory(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * 4)
        memory.set(image, forKey: url as NSURL, cost: cost)
    }
}
