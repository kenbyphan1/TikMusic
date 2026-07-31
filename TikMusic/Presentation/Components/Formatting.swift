import Foundation

/// Định dạng thời lượng video thành chuỗi "M:SS" hoặc "H:MM:SS".
enum DurationFormatter {

    /// Định dạng số giây thành chuỗi thời lượng ngắn gọn.
    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
