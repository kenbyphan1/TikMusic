import SwiftUI

/// Hỗ trợ Hero Animation / Matched Geometry khi điều hướng video.
///
/// Trên iOS 18 sử dụng transition `.zoom` chính thức (sourceID + namespace).
/// Trên iOS 17 fallback về transition mặc định — mã luôn biên dịch được.
extension View {

    /// Đánh dấu view nguồn cho hiệu ứng zoom khi điều hướng (hero source).
    ///
    /// - Parameters:
    ///   - id: định danh nguồn (ví dụ `video.id`).
    ///   - namespace: `Namespace.ID` dùng chung.
    @ViewBuilder
    func heroSource<ID: Hashable>(id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Áp dụng transition zoom cho view đích khi điều hướng (hero destination).
    ///
    /// - Parameters:
    ///   - sourceID: định danh nguồn tương ứng với `heroSource`.
    ///   - namespace: `Namespace.ID` dùng chung.
    @ViewBuilder
    func heroZoom<ID: Hashable>(sourceID: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }
}
