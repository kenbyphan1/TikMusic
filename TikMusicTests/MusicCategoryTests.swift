import XCTest
@testable import TikMusic

/// Unit test cho MusicCategory.
final class MusicCategoryTests: XCTestCase {

    /// Phải có đúng 13 chủ đề như yêu cầu.
    func testCategoryCount() {
        XCTAssertEqual(MusicCategory.allCases.count, 13)
    }

    /// Mọi chủ đề đều có chuỗi truy vấn không rỗng.
    func testEveryCategoryHasNonEmptySearchQuery() {
        for category in MusicCategory.allCases {
            XCTAssertFalse(
                category.searchQuery.isEmpty,
                "Chủ đề \(category.title) thiếu search query"
            )
        }
    }

    /// ID các chủ đề phải duy nhất.
    func testCategoryIDsAreUnique() {
        let ids = MusicCategory.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// Mọi chủ đề đều có biểu tượng không rỗng.
    func testEveryCategoryHasSymbol() {
        for category in MusicCategory.allCases {
            XCTAssertFalse(category.symbolName.isEmpty)
        }
    }

    /// Mọi chủ đề đều có gradient (>= 2 màu).
    func testEveryCategoryHasGradient() {
        for category in MusicCategory.allCases {
            XCTAssertGreaterThanOrEqual(category.gradientColors.count, 2)
        }
    }

    /// Raw value ánh xạ đúng title.
    func testTitleMatchesRawValue() {
        for category in MusicCategory.allCases {
            XCTAssertEqual(category.title, category.rawValue)
        }
    }
}
