import Foundation
import CryptoKit

/// Lỗi phát sinh khi thao tác với disk cache.
enum DiskCacheError: LocalizedError {
    /// Không thể tạo thư mục lưu trữ.
    case cannotCreateDirectory

    var errorDescription: String? {
        switch self {
        case .cannotCreateDirectory:
            return "Không thể tạo thư mục lưu trữ cache."
        }
    }
}

/// Bộ nhớ đệm trên đĩa (disk) với thời gian sống (TTL) và xoá sạch an toàn.
///
/// Mỗi key được băm (SHA-256) trước khi ghi thành tên file để tránh
/// ký tự không hợp lệ và tránh lộ thông tin nhạy cảm.
final class DiskCache {

    /// Thư mục gốc chứa dữ liệu cache.
    let directoryURL: URL

    /// Khởi tạo disk cache.
    ///
    /// - Parameters:
    ///   - name: tên cache, tạo subdirectory riêng trong Caches.
    ///   - cachesDirectory: thư mục cache gốc (mặc định là Caches của app).
    /// - Throws: `DiskCacheError.cannotCreateDirectory`.
    init(name: String, in cachesDirectory: URL? = nil) throws {
        let base = cachesDirectory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directoryURL = base.appending(path: name, directoryHint: .isDirectory)

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    /// Đọc dữ liệu cho một key.
    ///
    /// - Parameters:
    ///   - key: khoá dữ liệu.
    ///   - maxAge: thời gian tối đa (giây); dữ liệu cũ hơn bị coi là hết hạn.
    /// - Returns: dữ liệu hoặc `nil` nếu không tồn tại / hết hạn.
    func data(forKey key: String, maxAge: TimeInterval? = nil) -> Data? {
        let fileURL = fileURL(for: key)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        // Kiểm tra thời gian sống (TTL).
        if let maxAge {
            let age = Date().timeIntervalSince(modificationDate)
            if age > maxAge {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
        }

        return try? Data(contentsOf: fileURL)
    }

    /// Ghi dữ liệu cho một key.
    func set(_ data: Data, forKey key: String) {
        let fileURL = fileURL(for: key)
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Xoá dữ liệu của một key.
    func remove(forKey key: String) {
        try? FileManager.default.removeItem(at: fileURL(for: key))
    }

    /// Xoá toàn bộ dữ liệu trong cache.
    func removeAll() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )) ?? []
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    /// Xoá dữ liệu đã hết hạn so với `maxAge`.
    func removeExpired(olderThan maxAge: TimeInterval) {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []
        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modificationDate = values.contentModificationDate else {
                continue
            }
            if Date().timeIntervalSince(modificationDate) > maxAge {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    /// Tổng dung lượng (bytes) của toàn bộ cache.
    var totalSizeBytes: Int {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.fileSizeKey]
        )) ?? []
        return files.reduce(0) { partial, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return partial + size
        }
    }

    /// Tính tổng dung lượng trên luồng nền, trả về qua async.
    func totalSizeBytesAsync() async -> Int {
        await Task.detached(priority: .utility) { [directoryURL] in
            let files = (try? FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.fileSizeKey]
            )) ?? []
            return files.reduce(0) { partial, file in
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return partial + size
            }
        }.value
    }

    /// Đường dẫn file ổn định cho một key.
    private func fileURL(for key: String) -> URL {
        let hash = Self.sha256(key)
        return directoryURL.appending(path: hash).appendingPathExtension("data")
    }

    /// Băm SHA-256 một chuỗi thành hex string.
    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
