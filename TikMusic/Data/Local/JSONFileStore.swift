import Foundation

/// Bộ lưu trữ dữ liệu dạng JSON (thay thế SwiftData).
///
/// Đơn giản, không phụ thuộc framework, hoạt động ổn định trên mọi
/// phiên bản iOS. Mỗi repository dùng một file riêng trong thư mục
/// Application Support (hoặc giữ trong bộ nhớ khi dùng cho preview/test).
final class JSONFileStore {
    private let fileManager = FileManager.default
    private let isInMemory: Bool
    private let inMemoryData: NSMutableData
    private let directory: URL
    private let fileName: String

    /// Khởi tạo store ghi lên đĩa.
    init(fileName: String) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("TikMusic", isDirectory: true)
        directory = dir
        isInMemory = false
        inMemoryData = NSMutableData()
        self.fileName = fileName
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    /// Khởi tạo store giữ dữ liệu trong bộ nhớ (dùng cho preview/test).
    init(inMemory fileName: String) {
        directory = fileManager.temporaryDirectory
        isInMemory = true
        inMemoryData = NSMutableData()
        self.fileName = fileName
    }

    private var fileURL: URL {
        directory.appendingPathComponent(fileName)
    }

    /// Đọc dữ liệu (nil nếu chưa có dữ liệu).
    func load<T: Decodable>(_ type: T.Type) throws -> T? {
        let data: Data
        if isInMemory {
            guard inMemoryData.length > 0 else { return nil }
            data = inMemoryData as Data
        } else {
            guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
            data = try Data(contentsOf: fileURL)
        }
        guard !data.isEmpty else { return nil }
        return try JSONFileCoding.makeDecoder().decode(type, from: data)
    }

    /// Ghi dữ liệu (atomic khi ghi lên đĩa để tránh file hỏng).
    func save<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)

        if isInMemory {
            inMemoryData.setData(data)
        } else {
            try data.write(to: fileURL, options: [.atomic])
        }
    }

    /// Xoá toàn bộ dữ liệu.
    func clear() throws {
        if isInMemory {
            inMemoryData.setData(Data())
        } else if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}

/// Decoder dùng chung — cần đồng bộ kiểu ngày tháng với `save`.
enum JSONFileCoding {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
