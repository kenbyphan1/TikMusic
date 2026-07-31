import XCTest
@testable import TikMusic

/// Unit test cho MemoryCache và DiskCache.
final class CacheTests: XCTestCase {

    // MARK: - MemoryCache

    func testMemoryCacheSetAndGet() {
        let cache = MemoryCache<NSString, NSString>()

        cache.set("value1" as NSString, forKey: "key1" as NSString)

        XCTAssertEqual(cache.value(forKey: "key1" as NSString), "value1" as NSString)
        XCTAssertNil(cache.value(forKey: "missing" as NSString))
    }

    func testMemoryCacheRemoveAll() {
        let cache = MemoryCache<NSString, NSString>()
        cache.set("a" as NSString, forKey: "k1" as NSString)
        cache.set("b" as NSString, forKey: "k2" as NSString)

        cache.removeAll()

        XCTAssertNil(cache.value(forKey: "k1" as NSString))
        XCTAssertNil(cache.value(forKey: "k2" as NSString))
    }

    func testMemoryCacheEvictsOnCountLimit() {
        let cache = MemoryCache<NSString, NSString>(countLimit: 2)
        cache.set("a" as NSString, forKey: "k1" as NSString)
        cache.set("b" as NSString, forKey: "k2" as NSString)
        cache.set("c" as NSString, forKey: "k3" as NSString)

        // Với countLimit 2, ít nhất một phần tử phải bị loại bỏ.
        let remaining = [cache.value(forKey: "k1" as NSString),
                         cache.value(forKey: "k2" as NSString),
                         cache.value(forKey: "k3" as NSString)]
            .compactMap { $0 }.count
        XCTAssertLessThanOrEqual(remaining, 2)
    }

    // MARK: - DiskCache

    private func makeDiskCache() throws -> DiskCache {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return try DiskCache(name: "test-cache", in: tempDir)
    }

    func testDiskCacheWriteAndRead() throws {
        let cache = try makeDiskCache()
        defer { cache.removeAll() }

        let data = Data("hello world".utf8)
        cache.set(data, forKey: "greeting")

        XCTAssertEqual(cache.data(forKey: "greeting"), data)
        XCTAssertNil(cache.data(forKey: "missing"))
    }

    func testDiskCacheRemove() throws {
        let cache = try makeDiskCache()
        defer { cache.removeAll() }

        cache.set(Data("x".utf8), forKey: "key")
        cache.remove(forKey: "key")

        XCTAssertNil(cache.data(forKey: "key"))
    }

    func testDiskCacheRemoveAll() throws {
        let cache = try makeDiskCache()

        cache.set(Data("a".utf8), forKey: "k1")
        cache.set(Data("b".utf8), forKey: "k2")
        cache.removeAll()

        XCTAssertNil(cache.data(forKey: "k1"))
        XCTAssertNil(cache.data(forKey: "k2"))
        XCTAssertEqual(cache.totalSizeBytes, 0)
    }

    func testDiskCacheExpiry() throws {
        let cache = try makeDiskCache()
        defer { cache.removeAll() }

        cache.set(Data("old".utf8), forKey: "old")

        // maxAge = 0 → dữ liệu coi như hết hạn ngay.
        XCTAssertNil(cache.data(forKey: "old", maxAge: 0))
    }

    func testDiskCacheTotalSize() throws {
        let cache = try makeDiskCache()
        defer { cache.removeAll() }

        cache.set(Data(repeating: 0, count: 100), forKey: "100bytes")
        cache.set(Data(repeating: 0, count: 50), forKey: "50bytes")

        XCTAssertGreaterThanOrEqual(cache.totalSizeBytes, 150)
    }
}
