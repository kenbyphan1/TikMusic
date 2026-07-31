import XCTest
@testable import TikMusic

/// Unit test cho APIKeyProvider (ưu tiên runtime > build, placeholder bị bỏ qua).
final class APIKeyProviderTests: XCTestCase {

    /// Tạo provider với bundle chứa build key tạm thời.
    private func makeProvider(withKey key: String) -> APIKeyProvider {
        // Dọn sạch keychain còn sót từ test trước.
        try? APIKeyStore().delete()

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>YOUTUBE_API_KEY</key>
            <string>\(key)</string>
        </dict>
        </plist>
        """
        try? plist.write(to: tempDir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)

        return APIKeyProvider(bundle: Bundle(url: tempDir)!)
    }

    func testBuildKeyUsedWhenNoRuntimeKey() {
        let provider = makeProvider(withKey: "BUILD_KEY_123")
        XCTAssertEqual(provider.effectiveKey, "BUILD_KEY_123")
        XCTAssertTrue(provider.isConfigured)
    }

    func testRuntimeKeyTakesPrecedence() {
        let provider = makeProvider(withKey: "BUILD_KEY_123")
        provider.runtimeKey = "RUNTIME_KEY_456"

        XCTAssertEqual(provider.effectiveKey, "RUNTIME_KEY_456")
    }

    func testResetRuntimeKeyFallsBackToBuildKey() {
        let provider = makeProvider(withKey: "BUILD_KEY_123")
        provider.runtimeKey = "RUNTIME_KEY_456"

        provider.resetRuntimeKey()

        XCTAssertEqual(provider.effectiveKey, "BUILD_KEY_123")
        XCTAssertNil(provider.runtimeKey)
    }

    func testPlaceholderNotTreatedAsConfigured() {
        let provider = makeProvider(withKey: APIKeyProvider.placeholder)
        XCTAssertNil(provider.effectiveKey)
        XCTAssertFalse(provider.isConfigured)
    }

    func testEmptyBuildKeyNotConfigured() {
        let provider = makeProvider(withKey: "")
        XCTAssertNil(provider.effectiveKey)
    }
}
