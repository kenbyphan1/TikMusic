import XCTest
@testable import TikMusic

/// Unit test cho RequestBuilder.
final class RequestBuilderTests: XCTestCase {

    /// Query items phải được encode và gắn đúng.
    func testBuildAddsQueryItems() throws {
        let request = try RequestBuilder.build(from: TestEndpoint())

        XCTAssertEqual(request.httpMethod, HTTPMethod.get.rawValue)
        XCTAssertNotNil(request.url)
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        XCTAssertTrue(items.contains(URLQueryItem(name: "q", value: "phonk music")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "max", value: "10")))
    }

    /// Chuỗi query có ký tự đặc biệt phải được percent-encode.
    func testBuildPercentEncodesQuery() throws {
        let endpoint = TestEndpointWithSpecialChars()
        let request = try RequestBuilder.build(from: endpoint)
        XCTAssertNotNil(request.url)
        XCTAssertTrue(request.url!.absoluteString.contains("q%20"))
    }

    /// Headers mặc định phải có Accept và Content-Type.
    func testBuildSetsHeaders() throws {
        let request = try RequestBuilder.build(from: TestEndpoint())
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
    }

    /// URL với path có khoảng trắng vẫn dựng được.
    func testBuildHandlesPathWithSpace() throws {
        struct SpaceEndpoint: APIEndpoint {
            var baseURL: URL { URL(string: "https://example.com")! }
            var path: String { "/api /v1" }
            var method: HTTPMethod { .get }
        }
        let request = try RequestBuilder.build(from: SpaceEndpoint())
        XCTAssertNotNil(request.url)
    }
}

/// Endpoint có ký tự đặc biệt trong query.
private struct TestEndpointWithSpecialChars: APIEndpoint {
    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "q", value: "phonk music remix")]
    }
}
