import XCTest
@testable import TikMusic

/// Unit test cho MusicVideoMapper: chuyển DTO → Domain entity.
final class DTOMappingTests: XCTestCase {

    // MARK: - Search item mapping

    /// Map search item đầy đủ thông tin.
    func testMapSearchItem() throws {
        let response = try JSONDecoder().decode(
            YouTubeSearchResponseDTO.self,
            from: TestFixtures.searchResponseData
        )

        guard let item = response.items?.first else {
            return XCTFail("Thiếu item")
        }

        let video = MusicVideoMapper.video(from: item, category: .phonk)

        XCTAssertEqual(video?.id, "abc123")
        XCTAssertEqual(video?.title, "Phonk Test Song")
        XCTAssertEqual(video?.channelTitle, "Test Channel")
        XCTAssertEqual(video?.channelID, "UC123")
        XCTAssertEqual(video?.category, .phonk)
        XCTAssertEqual(video?.description, "Một bài hát phonk để test.")
        XCTAssertEqual(video?.thumbnailURL?.absoluteString, "https://i.ytimg.com/vi/abc123/mqdefault.jpg")
        XCTAssertNil(video?.viewCount, "Search item chưa có thống kê")
    }

    /// Item thiếu videoId (channel/playlist) → trả về nil.
    func testMapSearchItemWithoutVideoIDReturnsNil() {
        let item = YouTubeSearchItemDTO(
            kind: "youtube#channel",
            etag: nil,
            id: YouTubeResourceIDDTO(kind: "youtube#channel", videoId: nil, channelId: "UC123", playlistId: nil),
            snippet: nil
        )

        XCTAssertNil(MusicVideoMapper.video(from: item))
    }

    // MARK: - Video item mapping (chi tiết)

    /// Map video item đầy đủ thống kê + thời lượng.
    func testMapVideoItemWithStatistics() throws {
        let response = try JSONDecoder().decode(
            YouTubeVideosResponseDTO.self,
            from: TestFixtures.videosResponseData
        )

        guard let item = response.items?.first else {
            return XCTFail("Thiếu item")
        }

        let video = MusicVideoMapper.video(from: item)

        XCTAssertEqual(video?.id, "abc123")
        XCTAssertEqual(video?.viewCount, 1_234_567)
        XCTAssertEqual(video?.likeCount, 45_678)
        XCTAssertEqual(video?.duration, 253, "PT4M13S = 253 giây")
        XCTAssertEqual(video?.thumbnailHighURL?.absoluteString, "https://i.ytimg.com/vi/abc123/maxresdefault.jpg")
    }

    /// Trộn thống kê vào video có sẵn (search → videos).
    func testMergeStatisticsIntoVideo() throws {
        let searchResponse = try JSONDecoder().decode(
            YouTubeSearchResponseDTO.self,
            from: TestFixtures.searchResponseData
        )
        let videosResponse = try JSONDecoder().decode(
            YouTubeVideosResponseDTO.self,
            from: TestFixtures.videosResponseData
        )

        guard let searchItem = searchResponse.items?.first,
              let baseVideo = MusicVideoMapper.video(from: searchItem, category: .phonk),
              let videoItem = videosResponse.items?.first else {
            return XCTFail("Thiếu dữ liệu")
        }

        let merged = MusicVideoMapper.mergingStatistics(from: videoItem, into: baseVideo)

        XCTAssertEqual(merged.viewCount, 1_234_567)
        XCTAssertEqual(merged.duration, 253)
        XCTAssertEqual(merged.category, .phonk, "Giữ nguyên category gốc")
    }

    // MARK: - Parse ngày tháng

    /// Parse ngày chuẩn RFC 3339.
    func testParseDateStandard() {
        let date = MusicVideoMapper.parseDate("2025-01-15T10:00:00Z")
        XCTAssertNotNil(date)
    }

    /// Parse ngày có phần giây phân số.
    func testParseDateWithFractionalSeconds() {
        let date = MusicVideoMapper.parseDate("2025-01-15T10:00:00.500Z")
        XCTAssertNotNil(date)
    }

    /// Chuỗi rỗng / nil → nil.
    func testParseDateEmptyReturnsNil() {
        XCTAssertNil(MusicVideoMapper.parseDate(""))
        XCTAssertNil(MusicVideoMapper.parseDate(nil))
    }

    // MARK: - Parse thời lượng ISO 8601

    func testParseDurationVariants() {
        XCTAssertEqual(ISO8601DurationParser.parse("PT4M13S"), 253)
        XCTAssertEqual(ISO8601DurationParser.parse("PT1H2M3S"), 3723)
        XCTAssertEqual(ISO8601DurationParser.parse("PT1M"), 60)
        XCTAssertEqual(ISO8601DurationParser.parse("PT45S"), 45)
        XCTAssertEqual(ISO8601DurationParser.parse("P1DT2H"), 93_600)
        XCTAssertEqual(ISO8601DurationParser.parse("P2W"), 1_209_600)
        XCTAssertNil(ISO8601DurationParser.parse("P0D"))
    }

    func testParseDurationInvalidReturnsNil() {
        XCTAssertNil(ISO8601DurationParser.parse(""))
        XCTAssertNil(ISO8601DurationParser.parse("nonsense"))
        XCTAssertNil(ISO8601DurationParser.parse("PT"))
        XCTAssertNil(ISO8601DurationParser.parse("PTX"))
        XCTAssertNil(ISO8601DurationParser.parse("P"))
    }

    // MARK: - Format

    func testCompactNumberFormatter() {
        XCTAssertEqual(CompactNumberFormatter.compact(999), "999")
        XCTAssertEqual(CompactNumberFormatter.compact(1_234), "1.2K")
        XCTAssertEqual(CompactNumberFormatter.compact(1_234_567), "1.2M")
        XCTAssertEqual(CompactNumberFormatter.compact(5_678_901_234), "5.7B")
    }

    func testDurationFormatter() {
        XCTAssertEqual(DurationFormatter.format(45), "0:45")
        XCTAssertEqual(DurationFormatter.format(253), "4:13")
        XCTAssertEqual(DurationFormatter.format(3_723), "1:02:03")
    }
}
