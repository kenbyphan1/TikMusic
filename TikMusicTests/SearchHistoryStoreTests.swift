import XCTest
@testable import TikMusic

/// Unit test cho SearchHistoryStore.
final class SearchHistoryStoreTests: XCTestCase {

    /// Tạo store với suite riêng biệt để tránh ảnh hưởng lẫn nhau.
    private func makeStore() -> SearchHistoryStore {
        let suiteName = "test.searchhistory.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return SearchHistoryStore(defaults: defaults)
    }

    func testInitialEmpty() {
        XCTAssertTrue(makeStore().recentSearches.isEmpty)
    }

    func testAddStoresMostRecentFirst() {
        let store = makeStore()
        store.add("phonk")
        store.add("lofi")

        XCTAssertEqual(store.recentSearches, ["lofi", "phonk"])
    }

    func testAddDoesNotDuplicate() {
        let store = makeStore()
        store.add("phonk")
        store.add("phonk")

        XCTAssertEqual(store.recentSearches, ["phonk"])
    }

    func testAddIgnoresEmpty() {
        let store = makeStore()
        store.add("")
        store.add("   ")

        XCTAssertTrue(store.recentSearches.isEmpty)
    }

    func testAddRespectsLimit() {
        let store = makeStore()
        for index in 0..<20 {
            store.add("keyword-\(index)")
        }

        XCTAssertEqual(store.recentSearches.count, SearchHistoryStore.maxItems)
        XCTAssertEqual(store.recentSearches.first, "keyword-19")
    }

    func testRemoveItem() {
        let store = makeStore()
        store.add("phonk")
        store.add("lofi")

        store.remove("phonk")

        XCTAssertEqual(store.recentSearches, ["lofi"])
    }

    func testClear() {
        let store = makeStore()
        store.add("phonk")
        store.add("lofi")

        store.clear()

        XCTAssertTrue(store.recentSearches.isEmpty)
    }
}
