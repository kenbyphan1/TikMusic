import XCTest
@testable import TikMusic

/// Unit test cho APIClient: decode, xử lý lỗi HTTP, retry, decode lỗi.
final class APIClientTests: XCTestCase {

    /// Decode thành công với response 200.
    func testSendSuccessDecodes() async throws {
        let session = MockNetworkSession { _ in
            (TestFixtures.searchResponseData, HTTPTestResponse.make(statusCode: 200))
        }
        let client = APIClient(session: session, maxRetries: 0)

        let response = try await client.send(TestEndpoint(), as: YouTubeSearchResponseDTO.self)

        XCTAssertEqual(response.items?.count, 2)
        XCTAssertEqual(response.items?.first?.id?.videoId, "abc123")
        XCTAssertEqual(response.nextPageToken, "CAUQAA")
        XCTAssertEqual(session.requestCount, 1)
    }

    /// HTTP 404 ném lỗi httpStatus, không retry.
    func testSendHTTPErrorThrows() async throws {
        let session = MockNetworkSession { _ in
            (Data(), HTTPTestResponse.make(statusCode: 404))
        }
        let client = APIClient(session: session, maxRetries: 2)

        do {
            _ = try await client.send(TestEndpoint(), as: YouTubeSearchResponseDTO.self)
            XCTFail("Phải ném lỗi cho status 404")
        } catch let error as APIError {
            guard case .httpStatus(404, _) = error else {
                return XCTFail("Sai loại lỗi: \(error)")
            }
            XCTAssertEqual(session.requestCount, 1, "Không được retry lỗi 404")
        } catch {
            XCTFail("Sai loại lỗi: \(error)")
        }
    }

    /// Lỗi 5xx được retry rồi thành công.
    func testRetrySucceedsAfterServerError() async throws {
        // Dùng một session tự chọn response theo số lần gọi:
        // lần 1 trả 500, lần 2 trả 200.
        var attempt = 0
        let session = MockNetworkSession { _ in
            attempt += 1
            if attempt == 1 {
                return (Data(), HTTPTestResponse.make(statusCode: 500))
            }
            return (TestFixtures.searchResponseData, HTTPTestResponse.make(statusCode: 200))
        }

        let client = APIClient(session: session, maxRetries: 2, retryBaseDelay: 0.01)
        let response = try await client.send(TestEndpoint(), as: YouTubeSearchResponseDTO.self)

        XCTAssertEqual(response.items?.count, 2)
        XCTAssertEqual(attempt, 2, "Lần 1 lỗi 500, lần 2 thành công")
        XCTAssertEqual(session.requestCount, 2)
    }

    /// Dữ liệu không phải JSON → lỗi decoding, không retry.
    func testDecodingErrorThrows() async throws {
        let session = MockNetworkSession { _ in
            (TestFixtures.invalidJSONData, HTTPTestResponse.make(statusCode: 200))
        }
        let client = APIClient(session: session, maxRetries: 2)

        do {
            _ = try await client.send(TestEndpoint(), as: YouTubeSearchResponseDTO.self)
            XCTFail("Phải ném lỗi decoding")
        } catch let error as APIError {
            guard case .decoding = error else {
                return XCTFail("Sai loại lỗi: \(error)")
            }
            XCTAssertEqual(session.requestCount, 1, "Không được retry lỗi decoding")
        } catch {
            XCTFail("Sai loại lỗi: \(error)")
        }
    }

    /// Lỗi 403 quotaExceeded → APIError.quotaExceeded.
    func testQuotaExceededError() async throws {
        let session = MockNetworkSession { _ in
            (TestFixtures.quotaErrorData, HTTPTestResponse.make(statusCode: 403))
        }
        let client = APIClient(session: session, maxRetries: 0)

        do {
            _ = try await client.send(TestEndpoint(), as: YouTubeSearchResponseDTO.self)
            XCTFail("Phải ném lỗi quota")
        } catch let error as APIError {
            guard case .quotaExceeded = error else {
                return XCTFail("Sai loại lỗi: \(error)")
            }
        } catch {
            XCTFail("Sai loại lỗi: \(error)")
        }
    }

    /// Lỗi mạng (URLError) → APIError.network, có retry.
    func testNetworkErrorThrowsAndRetries() async throws {
        let flexible = MockNetworkSession { _ in
            throw URLError(.timedOut)
        }
        let client = APIClient(session: flexible, maxRetries: 1, retryBaseDelay: 0.01)

        do {
            _ = try await client.send(TestEndpoint(), as: YouTubeSearchResponseDTO.self)
            XCTFail("Phải ném lỗi mạng")
        } catch let error as APIError {
            guard case .network = error else {
                return XCTFail("Sai loại lỗi: \(error)")
            }
            XCTAssertEqual(flexible.requestCount, 2, "Lỗi mạng phải được retry 1 lần")
        } catch {
            XCTFail("Sai loại lỗi: \(error)")
        }
    }
}
